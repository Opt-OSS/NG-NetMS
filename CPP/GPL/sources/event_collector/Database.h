#pragma once

#include "Event.h"
#include "DbSettings.h"
#include "DbReturnCode.h"
#include "DbConnector.h"
#include <string>
#include <memory>
#include <pqxx/pqxx>
#include "CANParser/CANGlobalsParser.hpp"

#include <thread>
#include <mutex>
#include <condition_variable>
#include <iostream>
#include <queue>
#include <random>
#include <string>
#include <sstream>
#include <map>
#include <optional>

using namespace std;

class Database
{
        static constexpr int    INVALI_ROUTER_ID         = -1;
        static constexpr auto   DEFAULT_SEVERITY         = 10;
        static constexpr int    WRITE_TIMEOUT_MSEC       = 250;   // [msec] Periodic write timeout
        static constexpr size_t QUERY_QUEUE_LENGHT_LIMIT = 30000; // Query queue length limit
        static constexpr int    ORIGIN_LOOKUP_TIMEOUT    = 10;    // [sec] Router ID should be estimated again after timeout
        static constexpr size_t ORIGIN_LOOKUP_SIZE_LIMIT = 10000; // Lookup table size limit

    public:
        Database( bool Debug );
        ~Database( );
    	bool DeleteTables();
    	bool CreateTables();
        bool CreateCANGlobalVarsTable();
        bool InsertCanGlobalVariable(const std::string& name, int can_id, const std::string& description);
        bool Connect( const DbSettings& Settings  );
        DbReturnCode WriteEvent( const Event& event );
        bool GetCANDescription(int canId, std::string& canDescription, string& canName);
    private:
        string EscapeString( const string &Text );
        int RouterIdQuery( const string Query, const string &Hostname );
        int GetRouterId( const string &Hostname );

        bool PushQueryToQueue( string& Query );
        void WakeupWriterThread( );
        size_t GetQueryQueueSize( );
        DbReturnCode PerformQuery( const string& Query );
        DbReturnCode PerformQuery( const string& Query, pqxx::result& result );

        static void TimeoutThread( Database* This );
        static void WritterThread( Database* This );

    private:
        bool                            m_Debug;
        shared_ptr<DbConnector>         m_Connector;
        DbSettings                      m_DbConnectionData;

        bool                            m_TerminateThreads;
        std::condition_variable         m_CondVar;
        bool                            m_CondVarPredicate;
        std::mutex                      m_QueueLock;
        std::mutex                      m_QueryLock;
        std::queue<string>              m_QueryQueue;
        unique_ptr<thread>              m_WritterThread;
        unique_ptr<thread>              m_TimeoutThread;
        map<string, pair<time_t,int> >  m_OriginToRouterId;
};

