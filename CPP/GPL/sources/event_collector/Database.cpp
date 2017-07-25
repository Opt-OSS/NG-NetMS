#include "Database.h"
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
        string baseQuery = This->m_Debug ? "INSERT INTO events ( priority, severity, origin_ts, receiver_ts, origin, origin_id, facility, code, descr, raw_event ) VALUES " :
                                     "INSERT INTO events ( priority, severity, origin_ts, receiver_ts, origin, origin_id, facility, code, descr ) VALUES ";

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
    event.getOrigin( ) + "', '" + to_string( RouterId ) + "', '" + event.getFacility( ) + "', '" + event.getCode( ) + "', '" +EscapeString( event.getDescr( ) );

    if( m_Debug )
    {
        queryInsertEvent += "', '" + EscapeString( event.GetOriginalMessage( ) );
    }

    queryInsertEvent += "' )";

    PushQueryToQueue( queryInsertEvent );
    return DbReturnCode( DbReturnCode::Code::OK );
}
