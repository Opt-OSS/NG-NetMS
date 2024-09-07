#include "Database.h"
#include "DbConnector.h"
#include "SnmpOption.h"
#include "LogWriter.h"
#include "Model.h"
#include "Cryptography.h"
#include <sstream>
#include <algorithm>
#include <ctime>
#include <cstring>
#include <map>

using namespace ngnms;
using namespace std;

Database::Database(shared_ptr<LogWriter>& logger, bool mdef) :
m_Logger(logger),
m_MDef(mdef)
{

}

bool Database::Connect(const DbSettings& Settings)
{
    m_DbConnectionData = Settings;

    if( nullptr == m_Connector.get( ) )
    {
        m_Connector = shared_ptr<DbConnector>( new DbConnector( Settings ) );
    }

    return m_Connector->Connect().IsOk( );
}

bool Database::DeleteTables()
{
    m_Query = "DROP TABLE IF EXISTS public.origin_models CASCADE;"
    "DROP TABLE IF EXISTS public.origin_model_options CASCADE;"
    "DROP TABLE IF EXISTS public.observer_options CASCADE;"
    "DROP TABLE IF EXISTS public.observer_history_t1 CASCADE;"
    "DROP TABLE IF EXISTS public.observer_history_t2 CASCADE;"
    "DROP TABLE IF EXISTS public.observer_history_t3 CASCADE;"
    "DROP INDEX IF EXISTS observer_history_t1_observer_options_id;"
    "DROP INDEX IF EXISTS observer_history_t1_ts;"
    "DROP INDEX IF EXISTS observer_history_t2_observer_options_id;"
    "DROP INDEX IF EXISTS observer_history_t2_ts;";

    return Save();
}

bool Database::CreateTables()
{
    //Create "origin_models" table
    m_Query = "CREATE TABLE IF NOT EXISTS public.origin_models ( "
                "id SERIAL ,"
                "model CHARACTER VARYING( 256 ) COLLATE pg_catalog.default NOT NULL, "
                "vendor CHARACTER VARYING( 256 ) COLLATE pg_catalog.default NOT NULL, "
                "snmp_version CHARACTER VARYING( 2044 ) COLLATE pg_catalog.default NOT NULL, "
                "PRIMARY KEY ( id ), "
                "CONSTRAINT origin_modelsUnique UNIQUE( model,vendor ) );";

    //Create "origin_model_options" table
    m_Query += "CREATE TABLE IF NOT EXISTS public.origin_model_options ( "
                "id SERIAL, "
                "name CHARACTER VARYING( 256 ) COLLATE pg_catalog.default NOT NULL, "
                "unit CHARACTER VARYING( 128 ) COLLATE pg_catalog.default NOT NULL, "
                "oid CHARACTER VARYING( 512 ) COLLATE pg_catalog.default NOT NULL, "
                "type SMALLINT DEFAULT 0 NOT NULL, "
                "origin_models_id INTEGER NOT NULL, "
                "PRIMARY KEY ( id ) );";

    //Create "observer_options" table
    m_Query += "CREATE TABLE IF NOT EXISTS public.observer_options ( "
               "id SERIAL, "
               "track BOOLEAN NOT NULL,"
               "routers_id INTEGER NOT NULL, "
               "origin_model_options_id INTEGER NOT NULL,"
               "PRIMARY KEY ( id ) );";

    m_Query += "do $$ BEGIN "
     " IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'lnk_origin_models_origin_model_options') THEN "
     " ALTER TABLE public.origin_model_options "
     " ADD CONSTRAINT lnk_origin_models_origin_model_options "
     " FOREIGN KEY ( origin_models_id  ) "
     " REFERENCES public.origin_models ( id ) "
     " MATCH FULL ON DELETE Cascade ON UPDATE Cascade; "
     " END IF; "
     " END; $$;";

     m_Query += "do $$ BEGIN "
    " IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'lnk_origin_model_options_observer_options') THEN "
    " ALTER TABLE public.observer_options "
    " ADD CONSTRAINT lnk_origin_model_options_observer_options "
    " FOREIGN KEY ( origin_model_options_id  ) "
    " REFERENCES public.origin_model_options  ( id ) "
    " MATCH FULL ON DELETE Cascade ON UPDATE Cascade;"
    " END IF; "
    " END; $$;";

     m_Query += "do $$ BEGIN "
    " IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'lnk_routers_observer_options') THEN "
    " ALTER TABLE public.observer_options "
    " ADD CONSTRAINT lnk_routers_observer_options "
    " FOREIGN KEY ( routers_id       ) "
    " REFERENCES public.routers ( router_id ) "
    " MATCH FULL ON DELETE Cascade ON UPDATE Cascade;"
    " END IF; "
    " END; $$;";

    return Save();
}

bool Database::CreateHistoryTable(const SnmpVT& t)
{
    string tableName = "observer_history_t" + std::to_string(t);
    string typeName;

    switch (t)
    {
        case SnmpVT::BIGINT:
            typeName = "BIGINT";
        break;
        case SnmpVT::DOUBLE:
            typeName = "DOUBLE PRECISION";
        break;
        case SnmpVT::STRING:
            typeName = "CHARACTER VARYING(1024)";
        break;
        default:
            return false;
    }

    m_Query = "CREATE TABLE IF NOT EXISTS public." + tableName + " ( "
          "id SERIAL, "
          "value " + typeName + " NOT NULL, "
          "observer_options_id INTEGER NOT NULL, "
          "ts TIMESTAMP WITH TIME ZONE NOT NULL, "
          "PRIMARY KEY ( id ) );";

    m_Query += "do $$ BEGIN "
    " IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'lnk_observer_options_" + tableName + "') THEN "
    " ALTER TABLE public." + tableName + " "
    " ADD CONSTRAINT lnk_observer_options_" + tableName + " "
    " FOREIGN KEY ( observer_options_id) "
    " REFERENCES   public.observer_options  ( id ) "
    " MATCH FULL ON DELETE Cascade ON UPDATE Cascade; "
    " END IF; "
    " END; $$;";

    m_Query += " DO $$ BEGIN "
    " IF NOT EXISTS ( "
        " SELECT 1 "
        " FROM   pg_class c "
        " JOIN   pg_namespace n ON n.oid = c.relnamespace "
        " WHERE  c.relname = '" + tableName + "_observer_options_id' "
        " AND    n.nspname = 'public' "
        " ) THEN "
        " CREATE INDEX " + tableName + "_observer_options_id ON public." + tableName + " USING btree( observer_options_id ASC NULLS LAST ); "
        " END IF; "
        " END; $$;";

    m_Query += " DO $$ BEGIN "
    " IF NOT EXISTS ( "
        " SELECT 1 "
        " FROM   pg_class c "
        " JOIN   pg_namespace n ON n.oid = c.relnamespace "
        " WHERE  c.relname = '" + tableName + "_ts' "
        " AND    n.nspname = 'public' "
        " ) THEN "
        " CREATE INDEX " + tableName + "_ts ON public." + tableName + " USING btree( ts ASC NULLS LAST );"
        " END IF; "
        " END; $$;";

    return Save();
}

bool Database::ReadOrigins(pqxx::result& result)
{
    m_Query = "SELECT router_id, ip_addr, eq_vendor, eq_type, status FROM routers;";
    return Save(result);
}

bool Database::ReadOriginModels(pqxx::result& result)
{
    m_Query = "SELECT * FROM origin_models;";
    return Save(result);
}

bool Database::ReadOriginModelOptions(pqxx::result& result, const int mid)
{
    m_Query = "SELECT * FROM origin_model_options WHERE origin_models_id = " + std::to_string(mid) + ";";
    return Save(result);
}

bool Database::ReadObserverOptions(pqxx::result& result, const int rid)
{
    m_Query = "SELECT * FROM observer_options WHERE routers_id = " + std::to_string(rid) + ";";
    return Save(result);
}

inline int FindOptionPos(const pqxx::result& res, const string& fieldName, const string& fieldValue)
{
    for( int i = 0; i < res.size(); ++i )
    {
        if( fieldValue == res[i][fieldName].as<string>( ) )
        {
            return i;
        }
    }

    return -1;
}

bool Database::SetModelOption(ModelOption& opt)
{
    m_Query += "INSERT INTO origin_model_options ( name, oid, unit, origin_models_id) ";
    m_Query += "VALUES ( '" + opt._name + "', '" + opt._oid + "', '" +
                  opt._unit + "', " + std::to_string(opt._modelId) + ");";

    return true;
}

bool Database::AddModel(Model& model)
{
    m_Query = "INSERT INTO origin_models ( model, vendor, snmp_version) ";
    m_Query += "VALUES ( '" + model._model + "', '" +
                                                  model._vendor + "', '" +
                                                  model._snmpVersion + "');";
    m_Query += "SELECT MAX(id) AS LastID FROM origin_models;";
    return Add(model._id);
}

bool Database::FindModel(Model& model)
{
    m_Query = "SELECT id, snmp_version FROM origin_models ";
    m_Query += "WHERE vendor = '" + model._vendor + "' AND model = '" + model._model + "';";
    
    pqxx::result result;
    if (!Save(result))
          return false;

    if (result.empty() || result[0][0].is_null())
          return false;

    model._id = result[0]["id"].as<int>();
    model._snmpVersion = result[0]["snmp_version"].as<string>();
    
    return true;
}

bool Database::AddModelOption(ModelOption& opt)
{
    m_Query += "INSERT INTO origin_model_options ( name, oid, unit, origin_models_id) ";
    m_Query += "VALUES ( '" + opt._name + "', '" + opt._oid + "', '" +
                    opt._unit + "', " + std::to_string(opt._modelId) + ");";
    m_Query += "SELECT MAX(id) AS LastID FROM origin_model_options;";
    return Add(opt._id);
}

bool Database::AddObserverOption(SnmpOption& opt)
{
    m_Query = "INSERT INTO observer_options (origin_model_options_id, routers_id, track) ";
    m_Query += "VALUES ( " + to_string(opt._modelOptionId) + ", " +
                                                  to_string(opt._originId) + ", " +
                                                  (opt._track ? "true" : "false") + ");";
    m_Query += "SELECT MAX(id) AS LastID FROM observer_options;";
    return Add(opt._id);
}

bool Database::DelObserverOption(const int oid)
{
    m_Query = "DELETE FROM observer_options WHERE id = " + to_string(oid) + ";";
    return Save();
}

bool Database::SetOptionType( const int id, const int type )
{
    m_Query += "UPDATE origin_model_options SET type = " + std::to_string(type) + " WHERE id = " + std::to_string(id) + ";";
}

void Database::SetValue(SnmpValue& value, const time_t& ts)
{
    if( !value._type )
    {
        return;	//TODO temporary solution
    }

    m_Query += "INSERT INTO observer_history_t" + std::to_string(value._type)
                + " (observer_options_id, value, ts) VALUES ("
                + std::to_string(value._optionId) + ", ";

    m_Query += to_string(value._value.bigintV);

/*
* TODO:
* This functionality can not be tested properly
* without any available double type option
*/
#if 0    
    switch (value._type)
    {
        case SnmpVT::BIGINT:
            m_Query += to_string(value._value.bigintV);
        case SnmpVT::DOUBLE:
            m_Query += to_string(value._value.doubleV);
        case SnmpVT::STRING:
            m_Query += "'" + value._value.stringV + "'";
    }
#endif
				
    m_Query += ", to_timestamp(" + to_string(ts) + "));";
}

bool Database::GetComunityStr(int oid, string& comunity)
{
    m_Query = "SELECT community_ro FROM snmp_access WHERE id = "
                  "(SELECT snmp_access_id FROM router_snmp_access WHERE router_id = " + std::to_string(oid) + ");";

    pqxx::result result;
    if (!Save(result))
          return false;

    if (result.empty() || result[0][0].is_null())
          return false;

    string str = result[0][0].as<string>();
    comunity = Cryptography::DatabaseDecrypt(m_Key, str);

    return true;
}

bool Database::LoadDatabaseKey()
{
    const string GEN_SETTINGS_KEY = "chiave";
    m_Query = "SELECT value FROM general_settings WHERE name='" + GEN_SETTINGS_KEY + "'";

    pqxx::result result;
    if (!Save(result))
          return false;

    if (result.empty() || result[0][0].is_null())
          return false;

    m_Key = result[0][0].c_str();
    return true;
}

bool Database::Add(int& id)
{
    pqxx::result result;
    if (!Save(result))
          return false;

    if (result.empty() || result[0][0].is_null())
          return false;
    
    id = result[0][0].as<int>();
    return true;
}

bool Database::Save()
{
    if( m_Query.empty() )
    {
        return true;
    }

    try
    {
        pqxx::work work( *m_Connector->GetConnection() );
        work.exec(m_Query);
        work.commit();
        m_Ret = true;
    }
    catch( const exception &e )
    {
        m_Logger->LogError("Failed to execute Save() query. ", e.what());
        string error = "Failed Query: " + m_Query;
        m_Logger->LogError( error );
        m_Ret = false;
    }

    m_Query.clear();
    return m_Ret;
}

bool Database::Save(pqxx::result& result)
{
    if ( m_Query.empty() )
    {
        return true;
    }

    try
    {
        pqxx::work work( *m_Connector->GetConnection() );
        result = work.exec(m_Query);
        work.commit();
        m_Ret = true;
    }
    catch( const exception &e )
    {
        m_Logger->LogError("Failed to execute Save(r) query. ", e.what());
        string error = "Failed Query: " + m_Query;
        m_Logger->LogError( error );
        m_Ret = false;
    }

    m_Query.clear();
    return m_Ret;
}
