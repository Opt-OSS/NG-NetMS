#pragma once

#include <vector>
#include <string>
#include <sstream>

using namespace std;

class CollectorOptions
{
    public:
        enum class CollectorType
        {
            SYSLOG,
            SNMP
        };

        enum class DataSource
        {
            FILE,
            STDIN,
            FILE_POLLING,
            UDP,
            TCP
        };

    public:
        CollectorOptions( );
        bool Parse( vector<string>& Arguments );
        CollectorType GetCollectorType( );
        DataSource GetDataSource( );
        string GetFileName( );
        string GetRuleFileName( );
        string GetDbSettingsFileName( );
        string GetLogFileName( );
        int GetPort( );
        bool GetDebug( );

    private:
        class Option
        {
            public:
                Option( string Name, bool HasValue ):
                m_Name( Name ),
                m_HasValue( HasValue )
                {

                }

                string GetName( )
                {
                    return m_Name;
                }

                bool GetHasValue( )
                {
                    return m_HasValue;
                }

            private:
                string m_Name;
                bool   m_HasValue;
        };

        bool CheckForIlligalOptions( vector<string>& Arguments, vector<Option>& Options );
        bool IsOptionExist( vector<string>& Arguments, Option& option );
        string GetOptionValue( vector<string>& Arguments, Option& option );
        bool CheckOptionDublication( vector<string> Arguments );
        void ShowUsage( ostream& Stream );

    private:
        CollectorType   m_CollectorType;
        DataSource      m_DataSource;
        string          m_FileName;
        string          m_LogFileName;
        string          m_RuleFileName;
        string          m_DbSettingsFileName;
        int             m_Port;
        bool            m_Debug;
};
