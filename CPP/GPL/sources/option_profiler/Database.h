#pragma once

#include "DbReturnCode.h"
#include "DbConnector.h"
#include <vector>

using namespace std;

class Database
{
    public:
        bool Connect( const DbSettings& Settings  );
        DbReturnCode CreateTables( const vector<int>& Intervals );
        DbReturnCode InitialProfiling( const vector<int>& Intervals );
        DbReturnCode ProfileLastInterval( time_t Time, int Interval );

    private:
        static string MakeTimeStamp( time_t time );
        string IntervalToString( int Interval );
        DbReturnCode ProfileAllData( int Interval );
        DbReturnCode PerformQuery( pqxx::result& Result, string& Query );

    private:
        bool                            m_Debug;
        shared_ptr<DbConnector>         m_Connector;
        DbSettings                      m_DbConnectionData;
};
