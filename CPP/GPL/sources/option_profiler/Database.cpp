#include "Database.h"

bool Database::Connect( const DbSettings& Settings  )
{
    m_DbConnectionData = Settings;

    if( nullptr == m_Connector.get( ) )
    {
        m_Connector = shared_ptr<DbConnector>( new DbConnector( Settings ) );
    }

    return m_Connector->Connect().IsOk( );
}

string Database::IntervalToString( int Interval )
{
    if( Interval < 60 )
    {
        return to_string( Interval ) + "sec";
    }
    else if( Interval < 3600 )
    {
        return to_string( Interval / 60 ) + "min";
    }
    else
    {
        return to_string( Interval / 3600 ) + "hr";
    }
}

DbReturnCode Database::CreateTables( const vector<int>& Intervals )
{
    string createQueries;
    for( int interval : Intervals )
    {
        string createTableT1 = "CREATE TABLE IF NOT EXISTS observer_history_t1_" + IntervalToString( interval ) +
         " ( value BIGINT, observer_options_id INTEGER NOT NULL, ts TIMESTAMP WITH TIME ZONE NOT NULL );";

        string createTableT2 = "CREATE TABLE IF NOT EXISTS observer_history_t2_" + IntervalToString( interval ) +
         " ( value double precision, observer_options_id INTEGER NOT NULL, ts TIMESTAMP WITH TIME ZONE NOT NULL );";

        createQueries += createTableT1;
        createQueries += createTableT2;
    }

    pqxx::result result;
    return PerformQuery( result, createQueries );
}

DbReturnCode Database::InitialProfiling( const vector<int>& Intervals )
{
    for( int interval : Intervals )
    {
        DbReturnCode rc = ProfileAllData( interval );
        if( rc.IsFail( ) )
        {
            return rc;
        }
    }

    return DbReturnCode::Code::OK;
}

DbReturnCode Database::ProfileLastInterval( time_t Time, int Interval )
{
    time_t end_time   = Time - 1;
    time_t start_time = Time - Interval;
    time_t avg_time   = Time - Interval / 2;

    string profileT1 = "INSERT INTO observer_history_t1_" + IntervalToString( Interval ) + " (value,observer_options_id,ts) SELECT MAX( value ) AS value, MAX( observer_options_id) AS observer_options_id, '"
                     + MakeTimeStamp( avg_time ) + "' AS ts FROM observer_history_t1 WHERE ts BETWEEN '"
                     + MakeTimeStamp( start_time ) + "' AND '" + MakeTimeStamp( end_time ) + "' GROUP BY( observer_options_id );";

    string profileT2 = "INSERT INTO observer_history_t2_" + IntervalToString( Interval ) + " (value,observer_options_id,ts) SELECT MAX( value ) AS value, MAX( observer_options_id) AS observer_options_id, '"
                     + MakeTimeStamp( avg_time ) + "' AS ts FROM observer_history_t2 WHERE ts BETWEEN '"
                     + MakeTimeStamp( start_time ) + "' AND '" + MakeTimeStamp( end_time ) + "' GROUP BY( observer_options_id );";

    pqxx::result result;
    string commonQUery = profileT1 + profileT2;
    return PerformQuery( result, commonQUery );
}

DbReturnCode Database::ProfileAllData( int Interval )
{
    string commonQUery;
    string tableT1 = "observer_history_t1_" + IntervalToString( Interval );
    string tableT2 = "observer_history_t2_" + IntervalToString( Interval );

    string dropTableT1 = "DROP TABLE IF EXISTS observer_history_t1_" + IntervalToString( Interval ) + ";";
    string procedureT1 = "CREATE OR REPLACE FUNCTION profile_oprionsT1( integer, text ) RETURNS SETOF void AS $$ "
                         "declare "
                         "timestamps TIMESTAMP WITH TIME ZONE[] := ARRAY(SELECT to_timestamp( floor( ( extract('epoch' from ts ) / $1 ) ) * $1 ) AS interval_alias FROM observer_history_t1  GROUP BY interval_alias); "
                         "start_time TIMESTAMP WITH TIME ZONE; "
                         "end_time TIMESTAMP WITH TIME ZONE; "
                         "avg_time TIMESTAMP WITH TIME ZONE; "
                         "BEGIN "
                         "EXECUTE 'CREATE TABLE IF NOT EXISTS '|| quote_ident( $2 ) ||' ( value BIGINT, observer_options_id INTEGER NOT NULL, ts TIMESTAMP WITH TIME ZONE NOT NULL )'; "
                         "DROP TABLE IF EXISTS prf_tmp; "
                         "CREATE TEMP TABLE IF NOT EXISTS prf_tmp ( value BIGINT, observer_options_id INTEGER NOT NULL, ts TIMESTAMP WITH TIME ZONE NOT NULL ); "
                         "FOREACH end_time IN ARRAY timestamps "
                         "LOOP "
                         "avg_time   = to_timestamp( extract('epoch' from end_time ) - ($1 / 2)); "
                         "start_time = to_timestamp( extract('epoch' from end_time ) - ($1 - 1)); "
                         "INSERT INTO prf_tmp (value,observer_options_id,ts) SELECT MAX( value ) AS value, "
                         "MAX( observer_options_id) AS observer_options_id, "
                         "avg_time AS ts "
                         "FROM observer_history_t1 "
                         "WHERE ts BETWEEN start_time AND end_time GROUP BY( observer_options_id); "
                         "END LOOP; "
                         "EXECUTE 'INSERT INTO '|| quote_ident( $2 ) ||' SELECT * FROM prf_tmp'; "
                         "END; "
                         "$$ LANGUAGE plpgsql;";

    string executeProcedureT1 = "SELECT profile_oprionsT1( " + to_string( Interval ) + ",'" + tableT1 + "');";
    string dropProcedureT1 = "DROP FUNCTION profile_oprionsT1( integer, text);";

    commonQUery += dropTableT1;
    commonQUery += procedureT1;
    commonQUery += executeProcedureT1;
    commonQUery += dropProcedureT1;

    string dropTableT2 = "DROP TABLE IF EXISTS observer_history_t2_" + IntervalToString( Interval ) + ";";
    string procedureT2 = "CREATE OR REPLACE FUNCTION profile_oprionsT2( integer, text ) RETURNS SETOF void AS $$ "
                         "declare "
                         "timestamps TIMESTAMP WITH TIME ZONE[] := ARRAY(SELECT to_timestamp( floor( ( extract('epoch' from ts ) / $1 ) ) * $1 ) AS interval_alias FROM observer_history_t2 GROUP BY interval_alias); "
                         "start_time TIMESTAMP WITH TIME ZONE; "
                         "end_time TIMESTAMP WITH TIME ZONE; "
                         "avg_time TIMESTAMP WITH TIME ZONE; "
                         "BEGIN "
                         "EXECUTE 'CREATE TABLE IF NOT EXISTS '|| quote_ident( $2 ) ||' ( value double precision, observer_options_id INTEGER NOT NULL, ts TIMESTAMP WITH TIME ZONE NOT NULL )'; "
                         "DROP TABLE IF EXISTS prf_tmp; "
                         "CREATE TEMP TABLE IF NOT EXISTS prf_tmp ( value double precision, observer_options_id INTEGER NOT NULL, ts TIMESTAMP WITH TIME ZONE NOT NULL ); "
                         "FOREACH end_time IN ARRAY timestamps "
                         "LOOP "
                         "avg_time   = to_timestamp( extract('epoch' from end_time ) - ($1 / 2)); "
                         "start_time = to_timestamp( extract('epoch' from end_time ) - ($1 - 1)); "
                         "INSERT INTO prf_tmp (value,observer_options_id,ts) SELECT MAX( value ) AS value, "
                         "MAX( observer_options_id) AS observer_options_id, "
                         "avg_time AS ts "
                         "FROM observer_history_t2 "
                         "WHERE ts BETWEEN start_time AND end_time GROUP BY( observer_options_id); "
                         "END LOOP; "
                         "EXECUTE 'INSERT INTO '|| quote_ident( $2 ) ||' SELECT * FROM prf_tmp'; "
                         "END; "
                         "$$ LANGUAGE plpgsql;";

    string executeProcedureT2 = "SELECT profile_oprionsT2( " + to_string( Interval ) + ",'" + tableT2 + "');";
    string dropProcedureT2 = "DROP FUNCTION profile_oprionsT2( integer, text);";

    commonQUery += dropTableT2;
    commonQUery += procedureT2;
    commonQUery += executeProcedureT2;
    commonQUery += dropProcedureT2;

    pqxx::result result;
    return PerformQuery( result, commonQUery );
}

DbReturnCode Database::PerformQuery( pqxx::result& Result, string& Query )
{
    if( nullptr == m_Connector.get() )
    {
        DbConnector* connector = new DbConnector( m_DbConnectionData );
        DbReturnCode rc = connector->Connect( );
        if( rc.IsFail() )
        {
            delete connector;
            return rc;
        }

        m_Connector = shared_ptr<DbConnector> ( connector );
    }

    try
    {
        pqxx::work work( *m_Connector->GetConnection() );
        Result = work.exec( Query );
        work.commit();
    }
    catch( const exception &e )
    {
        return DbReturnCode( DbReturnCode::Code::QUERY_ERROR, string( "Failed to execute query: " + Query ) );
    }

    return DbReturnCode( DbReturnCode::Code::OK );
}

string Database::MakeTimeStamp( time_t time )
{
    char buffer[100];
    struct tm * timeinfo = localtime (&time);
    strftime( buffer, 100, "%F %T", timeinfo  );
    return move( string( buffer ) );
};
