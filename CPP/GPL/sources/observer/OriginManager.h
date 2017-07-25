#pragma once 

#include "Origin.h"
#include "Database.h"
#include "LogWriter.h"
#include "Profiler.h"
#include <map>
#include <stack>
#include <memory>
#include <thread>

using namespace std;

class OriginManager
{
    public:
        OriginManager( shared_ptr<Database>& db, shared_ptr<LogWriter>& logger, int imax );
        bool LoadOrigins( );
        bool LoadOriginThreads( );
        void Run( );
    
    private:
        shared_ptr<Database>    m_Database;
        shared_ptr<LogWriter>   m_Logger;
        Profiler                m_Profiler;
        vector<std::thread>     m_Threads;
        vector<Origin>          m_Origins;
		int						m_MaxInterval;
};
