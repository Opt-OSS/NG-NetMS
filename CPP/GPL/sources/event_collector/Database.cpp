#include "Database.h"
#include "EventProtocol.h"
#include <sstream>
#include <map>
#include <algorithm>
#include <ctime>
#include <cstring>
#include <iostream>
#include <ctime>

Database::Database( bool Debug ):
m_Debug( Debug ),
m_TerminateThreads( false ),
m_CondVarPredicate( false )
{
    m_WritterThread = unique_ptr<thread>( new thread( Database::WritterThread, this ) );
    m_TimeoutThread = unique_ptr<thread>( new thread( Database::TimeoutThread, this ) );
}

Database::~Database( )
{
    // Wait until all events will be stored to DB
    while( GetQueryQueueSize( ) )
    {
        this_thread::sleep_for( std::chrono::milliseconds( 1 ) );
    }

    m_TerminateThreads = true;
    m_TimeoutThread->join();

    WakeupWriterThread( );
    m_WritterThread->join();
}

bool Database::DeleteTables( )
{
	stringstream ss;
	ss << "DROP TABLE IF EXISTS events CASCADE;";
	ss << "DROP TABLE IF EXISTS event_protocol CASCADE;";

	return PerformQuery(ss.str()).IsOk();
}

bool Database::CreateTables( )
{
	stringstream ss;

	if(m_Debug)
	{
		ss << "CREATE TABLE IF NOT EXISTS events ( "
			  "event_id SERIAL ,"
			  "origin_ts timestamp with time zone ,"
			  "receiver_ts timestamp with time zone ,"
			  "origin character varying(64) ,"
			  "origin_id integer ,"
			  "facility character varying ,"
			  "code character varying(64) ,"
			  "descr character varying(10000) ,"
			  "priority character varying(10) ,"
			  "severity integer,"
			  "protocol integer NOT NULL ,"
			  "raw_event character varying"
			  ");";
	}
	else
	{
		ss << "CREATE TABLE IF NOT EXISTS events ( "
			  "event_id SERIAL ,"
			  "origin_ts timestamp with time zone ,"
			  "receiver_ts timestamp with time zone ,"
			  "origin character varying(64) ,"
			  "origin_id integer ,"
			  "facility character varying ,"
			  "code character varying(64) ,"
			  "descr character varying(10000) ,"
			  "priority character varying(10) ,"
			  "severity integer,"
			  "protocol integer NOT NULL"
			  ");";
	}

	ss << "CREATE TABLE IF NOT EXISTS event_protocol ( "
				  "id integer PRIMARY KEY,"
				  "name character varying(64)"
			      ");";

	ss << "CREATE INDEX IF NOT EXISTS event_id_idx ON events USING btree( event_id ASC NULLS LAST );";
	ss << "CREATE INDEX IF NOT EXISTS events_origin_ts_idx ON events USING btree( origin_ts ASC NULLS LAST );";
	ss << "CREATE INDEX IF NOT EXISTS event_receiver_ts_idx ON events USING btree( receiver_ts ASC NULLS LAST );";

	if( PerformQuery(ss.str()).IsFail())
	{
		return false;
	}

	for( auto& e : GetProtocolToStringMapping())
	{
		string query = "INSERT INTO event_protocol (id, name) VALUES(" + to_string( static_cast<int>(e.first) ) + ", '" + e.second  + "');";
		PerformQuery(query);
	}

    if(!CreateCANGlobalVarsTable())
    {
        return false;
    }

	return true;
}

bool Database::CreateCANGlobalVarsTable() {
    std::string query = R"(
        CREATE TABLE IF NOT EXISTS can_global_variables (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            can_id INT NOT NULL,
            description TEXT
        );
    )";
    if( PerformQuery(query).IsFail())
	{
		return false;
	}
    CANGlobalsParser staticsParser("globals.rgf");
    for (const auto& entry : staticsParser.GetParsedEntries()) {
        if(!InsertCanGlobalVariable(entry.name, entry.can_id, entry.description))
        {
            return false;
        }
    }
    return true;
}

bool Database::InsertCanGlobalVariable(const std::string& name, int can_id, const std::string& description) {
    std::string query = "INSERT INTO can_global_variables (name, can_id, description) VALUES ('" + 
                        name + "', '" + std::to_string(can_id) + "', '" + description + "');";
    return PerformQuery(query).IsFail(); 
}


bool Database::Connect( const DbSettings& Settings  )
{
    m_DbConnectionData = Settings;

    if( nullptr == m_Connector.get( ) )
    {
        m_Connector = shared_ptr<DbConnector>( new DbConnector( Settings ) );
    }

    return m_Connector->Connect().IsOk( );
}

void Database::WakeupWriterThread( )
{
    m_CondVarPredicate = true;
    m_CondVar.notify_one();
}

/*  static */
void Database::TimeoutThread( Database* This )
{
    while( !This->m_TerminateThreads )
    {
        this_thread::sleep_for( std::chrono::milliseconds( WRITE_TIMEOUT_MSEC ) );
        This->WakeupWriterThread( );
    }
}

/* static */
void Database::WritterThread( Database* This )
{
    while( !This->m_TerminateThreads )
    {
        // Wait for signal from timeout thread or from main thread
        std::unique_lock<std::mutex> locker( This->m_QueueLock );

        while( !This->m_CondVarPredicate ) // used to avoid spurious wakeups
        {
            This->m_CondVar.wait( locker );
        }

        This->m_CondVarPredicate = false;
        string baseQuery = This->m_Debug ? "INSERT INTO events ( priority, severity, origin_ts, receiver_ts, origin, origin_id, facility, code, descr, protocol, raw_event ) VALUES " :
                                     "INSERT INTO events ( priority, severity, origin_ts, receiver_ts, origin, origin_id, facility, code, descr, protocol ) VALUES ";

        string multipleQueries = This->m_QueryQueue.empty( ) ? "" : baseQuery;
        while( !This->m_QueryQueue.empty( ) )
        {
            multipleQueries += This->m_QueryQueue.front( ) + ( This->m_QueryQueue.size( ) > 1 ? "," : ";" );
            This->m_QueryQueue.pop();
        };

        std::unique_lock<std::mutex> locker2( This->m_QueryLock );
        if( nullptr != This->m_Connector && This->m_Connector->IsConnected( ) )
        {
            try
            {
                pqxx::work work( *This->m_Connector->GetConnection() );
                work.exec( multipleQueries );
                work.commit();
            }
            catch( const exception &e )
            {
                if( m_Debug )
                {
                cerr << "WritterThread query = " << multipleQueries << endl;
                }
                cerr << "WritterThread exception = " << e.what( ) << endl;
            }
            catch( ... )
            {
                cerr << "WritterThread Unknown exception = " << endl;
            }
        }
    }
}

size_t Database::GetQueryQueueSize( )
{
    std::unique_lock<std::mutex> locker( m_QueueLock );
    return m_QueryQueue.size( );
}

bool Database::PushQueryToQueue( string& Query )
{
    while( GetQueryQueueSize( ) >= QUERY_QUEUE_LENGHT_LIMIT )
    {
        WakeupWriterThread( );
        this_thread::sleep_for( std::chrono::milliseconds( 1 ) );
    }

    std::unique_lock<std::mutex> locker( m_QueueLock );
    m_QueryQueue.push( Query );

    if(  m_QueryQueue.size( ) >= QUERY_QUEUE_LENGHT_LIMIT/2 )
    {
         WakeupWriterThread( );
    }

    return true;
}

int Database::RouterIdQuery( const string Query, const string &Hostname )
{
    std::unique_lock<std::mutex> locker( m_QueryLock );

    if( nullptr == m_Connector || !m_Connector->IsConnected( ) )
    {
        return INVALI_ROUTER_ID;
    }

    string routerIdQuery = Query  + "'" + Hostname + "'";

    try
    {
        pqxx::work work( *m_Connector->GetConnection() );
        pqxx::result result = work.exec( routerIdQuery );
        work.commit();

        if( result.size( ) )
        {
            return result[0][0].as<int>();
        }
    }
    catch( const exception &e )
    {
        cerr << "RouterIdQuery exception = " << e.what( ) << endl;
    }
    catch( ... )
    {
        cerr << "RouterIdQuery Unknown exception = " << endl;
    }

    return INVALI_ROUTER_ID;
}

int Database::GetRouterId( const string &Hostname )
{
    int RouterId = RouterIdQuery( "SELECT router_id FROM routers WHERE HOST( ip_addr ) = ", Hostname );
    if( INVALI_ROUTER_ID == RouterId )
    {
        RouterId = RouterIdQuery( "select router_id from interfaces where HOST(ip_addr) = ", Hostname );
        if( INVALI_ROUTER_ID == RouterId )
        {
            RouterId = RouterIdQuery( "SELECT router_id FROM routers WHERE name = ", Hostname );
        }
    }

    return RouterId;
}

string Database::EscapeString( const string &Text )
{
    string text;
    for( auto symbol : Text )
    {
        text.insert ( text.end( ), '\'' == symbol ? 2 : 1, symbol );
    }

    return move( text );
}

DbReturnCode Database::WriteEvent( const Event& event )
{
    time_t timeNow  = time( 0 );
    int    RouterId = INVALI_ROUTER_ID;

    if( ORIGIN_LOOKUP_SIZE_LIMIT <= m_OriginToRouterId.size( ) )
    {
        auto predicate = []( pair<string, pair<time_t,int> >  val ) { return val.second.second == -1; };

        auto i = m_OriginToRouterId.begin();
        while ( ( i = find_if( i, m_OriginToRouterId.end(), predicate ) ) != m_OriginToRouterId.end( ) )
        {
            m_OriginToRouterId.erase( i++ );
        }

        cout << "Erase due to overflow" << endl;
    }

    if( m_OriginToRouterId.find( event.getOrigin( ) ) == m_OriginToRouterId.end( ) )
    {
        RouterId = GetRouterId( event.getOrigin( ) );
        m_OriginToRouterId[ event.getOrigin( ) ] = make_pair( timeNow, RouterId );
    }
    else
    {
        pair<time_t,int> entry = m_OriginToRouterId[ event.getOrigin( ) ];
        if( (timeNow -  entry.first) < ORIGIN_LOOKUP_TIMEOUT )
        {
            RouterId = entry.second;
        }
        else
        {
            RouterId = GetRouterId( event.getOrigin( ) );
            m_OriginToRouterId[ event.getOrigin( ) ] = make_pair( timeNow, RouterId );
        }
    }

    int severity = event.getSeverity( );
    if( 0 == severity )
    {
        severity = DEFAULT_SEVERITY;
    }

    string queryInsertEvent = " ( '" + event.getPriority( ) +  "', '" + to_string( severity ) + "', '" + event.getOrign_Ts( ) + "', '" + event.getTs() + "', '" +
    event.getOrigin( ) + "', '" + to_string( RouterId ) + "', '" + event.getFacility( ) + "', '" + event.getCode( ) + "', '" + EscapeString( event.getDescr( ) ) +
    "', '" + to_string( static_cast<int>( event.getProtocol()) );

    if( m_Debug )
    {
        queryInsertEvent += "', '" + EscapeString( event.GetOriginalMessage( ) );
    }

    queryInsertEvent += "' )";

    PushQueryToQueue( queryInsertEvent );
    return DbReturnCode( DbReturnCode::Code::OK );
}

bool Database::GetCANDescription(int canId, std::string& canDescription)
{
    pqxx::result result;

    std::string query = "SELECT description FROM can_global_variables WHERE can_id = " + std::to_string(canId) + ";";

    DbReturnCode returnCode = PerformQuery(query, result);

    if (returnCode.IsFail()) {
        std::cerr << "Failed to execute query for CANid: " << canId << std::endl;
        return false;
    }

    if (!result.empty()) {
        canDescription = result[0][0].as<std::string>();
        return true;
    }

    return false;
}

DbReturnCode Database::PerformQuery( const string& Query )
{
	pqxx::result result;
	return PerformQuery(Query, result);
}

DbReturnCode Database::PerformQuery( const string& Query, pqxx::result& result )
{
    try
    {
        pqxx::work work( *m_Connector->GetConnection() );
        result = work.exec( Query );
        work.commit();
    }
    catch( const exception &e )
    {
        return DbReturnCode( DbReturnCode::Code::QUERY_ERROR, string( "Failed to execute query: " + Query ) );
    }

    return DbReturnCode( DbReturnCode::Code::OK );
}

