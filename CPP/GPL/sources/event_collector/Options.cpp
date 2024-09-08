#include "Options.h"
#include <iostream>
#include <map>

#include <boost/program_options/options_description.hpp>
#include <boost/program_options/parsers.hpp>
#include <boost/program_options/variables_map.hpp>
#include <boost/tokenizer.hpp>
#include <boost/token_functions.hpp>
#include <boost/asio.hpp>

using namespace std;
using namespace boost::program_options;

#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>

namespace fs = boost::filesystem;

static map<string, Options::SourceType> sourceType =
{
	{ "syslog-file",		Options::SourceType::SYSLOG_FILE },
	{ "syslog-polling",		Options::SourceType::SYSLOG_FILE_POLLING },
	{ "syslog-udp", 		Options::SourceType::SYSLOG_UDP },
	{ "syslog-tcp",			Options::SourceType::SYSLOG_TCP },
	{ "snmp-file",			Options::SourceType::SNMP_FILE },
	{ "snmp-polling",		Options::SourceType::SNMP_FILE_POLLING },
	{ "netflow-udp",		Options::SourceType::NETFLOW_UDP },
	{ "netflow-tcp",		Options::SourceType::NETFLOW_TCP },
	{ "apache-file",		Options::SourceType::APACHE_FILE },
	{ "apache-polling",		Options::SourceType::APACHE_FILE_POLLING },
	{ "custom1-file",		Options::SourceType::CUSTOM1_FILE },
	{ "custom1-polling",	Options::SourceType::CUSTOM1_FILE_POLLING },
	{ "custom2-file",		Options::SourceType::CUSTOM2_FILE },
	{ "custom2-polling",	Options::SourceType::CUSTOM2_FILE_POLLING },
	{ "can-bus-file",		Options::SourceType::CAN_BUS_FILE },
	{ "can-bus-polling",	Options::SourceType::CAN_BUS_FILE_POLLING },

};

Options::Options( ):
m_SourceType(SourceType::SNMP_FILE_POLLING),
m_FileName( "/var/log/syslog" ),
m_LogFileName( "ngnms_collector.log" ),
m_RuleFileName( "rules.txt" ),
m_DbSettingsFileName( "db.cfg" ),
m_Port( 514 ),
m_BindIPAddress("0.0.0.0"),
m_OriginalTs(false),
m_Debug( false ),
m_RenewTables(false)
{

}

bool Options::Parse(  int argc, char * argv[] )
{
	try
	{
	    string dataSource;
		options_description desc( "Program Usage", 1024, 512 );

		desc.add_options()
					   ( "help,h",     "This help message")
					   ( "drop,D",										    "Create/renew collector database tables, if verbose option > 0 then tables created with debug fields")
					   ( "source,s",  value<string>(&dataSource),           "syslog-file,\nsyslog-polling,\nsyslog-udp,\nsyslog-tcp,\nsnmp-file,\nsnmp-polling,\nnetflow-udp,\nnetflow-tcp,\napache-file,\napache-polling,\ncustom1-file,\ncustom1-polling,\ncustom2-file,\ncustom2-polling,\ncan-bus-file,\ncan-bus-polling" )
					   ( "conf_db,c", value<string>(&m_DbSettingsFileName), "Configuration file with encrypted data base options. Default is ./db.cfg" )
					   ( "file,f",    value<string>(&m_FileName),           "File location. Default is /var/log/syslog" )
					   ( "port,p",    value<int>(&m_Port),                  "Port for UDP/TCP 0-65535. Default is 514" )
					   ( "ip,I",  value<string>(&m_BindIPAddress),          "Listen on IP address, default is 0.0.0.0")
					   ( "rule,r",    value<string>(&m_RuleFileName),       "Rule file location. Default is rule.txt" )
					   ( "log,l",     value<string>(&m_LogFileName),        "Log file location. Default is ./ngnms_collector.log" )
					   ( "origin_ts,o",										"Use original time stamps for events")
					   ( "verbose,v",                                       "Verbose debug messages" )
		;

		variables_map vm;
		store( parse_command_line( argc, argv, desc ), vm );


		if( vm.count( "help" ))
		{
			std::cout << desc << "\n";
			return false;
		}
		if( vm.count( "origin_ts" ) )
		{
			m_OriginalTs = true;
		}

		if( vm.count( "verbose" ) )
		{
			m_Debug = true;
		}

		if( vm.count( "drop" ) )
		{
			m_RenewTables = true;
		}

		notify( vm );

		if( sourceType.end() == sourceType.find(dataSource))
		{
		    std::cout << "Wrong source '" << dataSource << "'" << std::endl;
			std::cout << desc << std::endl;
			return false;
		}

		if( m_Port < 0 || m_Port > 65535)
		{
		    std::cout << "Wrong port: " << to_string(m_Port) <<  std::endl;
			std::cout << desc << std::endl;
			return false;
		}


		m_SourceType = sourceType[dataSource];

		boost::system::error_code ec;
		boost::asio::ip::address::from_string( m_BindIPAddress, ec );
		if ( ec ){
		    std::cout << "Wrong listening IP address '" << m_BindIPAddress << "': " <<  ec.message( ) << std::endl;
		    std::cout << desc << std::endl;
			return false;
		}

	}
	catch( std::exception& e )
	{
		std::cerr << "Error: " << e.what() << "\n";
		return false;
	}
	catch(...)
	{
		std::cerr << "Unknown error!" << "\n";
		return false;
	}

	return true;
}

Options::SourceType Options::GetSourceType( )
{
	return m_SourceType;
}

string  Options::GetFileName( )
{
    return m_FileName;
}

string Options::GetRuleFileName( )
{
    return m_RuleFileName;
}

string Options::GetDbSettingsFileName( )
{
    return m_DbSettingsFileName;
}

string Options::GetLogFileName( )
{
    return m_LogFileName;
}

int Options::GetPort( )
{
    return m_Port;
}

string Options::GetBindIPAddress( )
{
    return m_BindIPAddress;
}

bool Options::GetOriginalTs()
{
	return m_OriginalTs;
}

bool Options::GetDebug( )
{
    return m_Debug;
}

bool Options::GetRenewTables( )
{
	return m_RenewTables;
}
