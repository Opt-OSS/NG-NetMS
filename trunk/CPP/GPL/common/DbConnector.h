#pragma once
#include <string>
#include <pqxx/pqxx>
#include "DbReturnCode.h"
#include "DbSettings.h"

using namespace std;

class DbConnector
{
    public:
        DbConnector( const DbSettings& DbConnection ) throw( );
        ~DbConnector() throw( );
        DbReturnCode Connect( );
        bool IsConnected( );
        pqxx::asyncconnection* GetConnection( );

    private:
        static string DbConnectionDataToString( const DbSettings& DbConnection );

    private:
        DbSettings  m_DbConnectionData;
        pqxx::asyncconnection* m_Connection;
        bool                   m_Connected;
};
