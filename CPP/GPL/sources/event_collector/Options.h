#pragma once

#include <vector>
#include <string>
#include <sstream>

using namespace std;

class Options
{
    public:
		enum class SourceType
		{
			SYSLOG_FILE,
			SYSLOG_FILE_POLLING,
			SYSLOG_UDP,
			SYSLOG_TCP,
			SNMP_FILE,
			SNMP_FILE_POLLING,
			NETFLOW_UDP,
			NETFLOW_TCP,
			APACHE_FILE,
			APACHE_FILE_POLLING,
			CUSTOM1_FILE,
			CUSTOM1_FILE_POLLING,
			CUSTOM2_FILE,
			CUSTOM2_FILE_POLLING,
      CAN_BUS_FILE,
      CAN_BUS_FILE_POLLING
		};

    public:
        Options( );
        bool Parse(  int argc, char * argv[] );
        SourceType GetSourceType( );
        string GetFileName( );
        string GetRuleFileName( );
        string GetDbSettingsFileName( );
        string GetLogFileName( );
        int GetPort( );
        string GetBindIPAddress( );
        bool GetOriginalTs();
        bool GetDebug( );
        bool GetRenewTables( );

    private:
        SourceType		m_SourceType;
        string          m_FileName;
        string          m_LogFileName;
        string          m_RuleFileName;
        string          m_DbSettingsFileName;
        int             m_Port;
        string          m_BindIPAddress;
        bool 			m_OriginalTs;
        bool            m_Debug;
        bool			m_RenewTables;
};
