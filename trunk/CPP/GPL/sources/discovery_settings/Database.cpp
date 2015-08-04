#include "Database.h"
#include <sstream>
#include <algorithm>
#include <pqxx/pqxx>
#include <ctime>
#include <cstring>
#include <map>
#include "DbConnector.h"
#include "Cryptography.h"
#include "DbProviderDiscoverySettings.h"

static string GEN_SETTINGS_KEY        = "chiave";

DbReturnCode Database::SetDiscoverySettings( DiscoverySettings& Settings )
{
    DbProviderDiscoverySettings<Database> discoverySettings( *this );
    return discoverySettings.SetDiscoverySettings( Settings );
}

DbReturnCode Database::GetDiscoverySettings( DiscoverySettings& Settings )
{
  DbProviderDiscoverySettings<Database> discoverySettings( *this );
  return discoverySettings.GetDiscoverySettings( Settings );
}

void Database::Connect( const DbSettings& Settings )
{
    m_DbConnectionData = Settings;
}

DbReturnCode Database::GetDatabaseKey( string &Key )
{
    DbConnector connector( m_DbConnectionData );
    DbReturnCode rc = connector.Connect();

    if( rc.IsFail() )
    {
        return rc;
    }

    string dbQueryQuery  = "SELECT value FROM general_settings WHERE name='";
           dbQueryQuery += GEN_SETTINGS_KEY;
           dbQueryQuery += "'";
    try
    {
        pqxx::work work( *connector.GetConnection() );
        pqxx::result result = work.exec( dbQueryQuery );
        work.commit();
        Key = result[0][0].c_str( );
    }
    catch( const exception &e )
    {
        string error_text( "Failed to execute query: " + dbQueryQuery );
        return DbReturnCode( DbReturnCode::Code::QUERY_ERROR, error_text );
    }

    return DbReturnCode( DbReturnCode::Code::OK );
}

DbReturnCode Database::GetGeneralSetting( string Name, string& Value )
{
    DbConnector connector( m_DbConnectionData );
    DbReturnCode rc = connector.Connect();

    if( rc.IsFail() )
    {
        return rc;
    }

    string dbQueryQuery = "SELECT value FROM general_settings WHERE name='";
           dbQueryQuery +=  Name;
           dbQueryQuery += "'";

    string EncryptedValue;
    try
    {
        pqxx::work work( *connector.GetConnection() );
        pqxx::result result = work.exec( dbQueryQuery );
        work.commit();
        EncryptedValue = result[0][0].c_str( );
    }
    catch( const exception &e )
    {
        string error_text( "Failed to execute query: " + dbQueryQuery );
        return DbReturnCode( DbReturnCode::Code::QUERY_ERROR, error_text );
    }

    string Key;
    rc = GetDatabaseKey( Key );
    if( rc.IsFail() )
    {
        return rc;
    }

    stringstream ss;
    ss << Cryptography::DatabaseDecrypt( Key, EncryptedValue );
    ss >> Value;

    return DbReturnCode( DbReturnCode::Code::OK );
}

DbReturnCode Database::IsGeneralSettingExist( string Name, bool &Exist )
{
    Exist = false;
    DbConnector connector( m_DbConnectionData );
    DbReturnCode rc = connector.Connect();
    if( rc.IsFail() )
    {
        return rc;
    }

    string dbQuery  = "SELECT COUNT(*) FROM general_settings WHERE name='";
           dbQuery +=  Name;
           dbQuery += "'";

    try
    {
        pqxx::work work( *connector.GetConnection() );
        pqxx::result result = work.exec( dbQuery );
        work.commit();

        if( result.size( ) )
        {
            Exist = true;
        }
    }
    catch( const exception &e )
    {
        string error_text( "Failed to execute query: " + dbQuery );
        return DbReturnCode( DbReturnCode::Code::QUERY_ERROR, error_text );
    }

    return DbReturnCode( DbReturnCode::Code::OK );
}

DbReturnCode Database::SetGeneralSetting( string Name, string Value  )
{
    bool settingExist;
    DbReturnCode rc = IsGeneralSettingExist( Name, settingExist );
    if( rc.IsFail() )
    {
            return rc;
    }

    string Key;
    rc = GetDatabaseKey( Key );
    if( rc.IsFail() )
    {
        return rc;
    }

    string encryptedValue = Cryptography::DatabaseEncrypt( Key, Value );

    DbConnector connector( m_DbConnectionData );
    rc = connector.Connect();
    if( rc.IsFail() )
    {
            return rc;
    }

    string query;
    if( settingExist )
    {
        stringstream ss;
        ss << "UPDATE general_settings SET ";
        ss << "value='";
        ss << encryptedValue;
        ss << "' WHERE name='";
        ss << Name;
        ss << "'";
        query = ss.str();
    }
    else
    {
        stringstream ss;
        ss << "INSERT INTO general_settings (name,value) VALUES (";
        ss << Name;
        ss << ",";
        ss << Value;
        ss << ")";
        query = ss.str();
    }

    try
    {
        pqxx::work work( *connector.GetConnection() );
        work.exec( query );
        work.commit();
    }
    catch( const exception &e )
    {
        string error_text( "Failed to execute query: " + query );
        return DbReturnCode( DbReturnCode::Code::QUERY_ERROR, error_text );
    }

    return DbReturnCode( DbReturnCode::Code::OK );
}
