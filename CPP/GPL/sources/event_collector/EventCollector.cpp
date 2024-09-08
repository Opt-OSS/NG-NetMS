#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <signal.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#include "EventType.h"
#include "Triggers.h"
#include "Database.h"
#include "Event.h"

#include <memory>
#include <algorithm>
#include <vector>
#include <string>
#include <sstream>

#include "Classifier.h"
#include "Options.h"

// Parsers
#include "ParserSyslog.h"
#include "SnmpParser.h"
#include "NetFlowParser.h"
#include "ApacheParser.h"
#include "Custom1Parser.h"
#include "Custom2Parser.h"
#include "CANParser.h"

// Logger
#include "Logger.h"

// Syslog data providers
#include "SyslogFileDP.h"
#include "SyslogFilePollingDP.h"
#include "SyslogTcpDP.h"
#include "SyslogUdpDP.h"
#include "NetFlowTcpDP.h"
#include "NetFlowUdpDP.h"
#include "ApacheFileDP.h"
#include "ApacheFilePollingDP.h"

#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>
#include "Configuration.h"

using namespace std;

namespace fs = boost::filesystem;

class EventCollector: public ClassifierListener, public DataProviderListener, public ParserListener
{
    public:
        static EventCollector& GetInstance( )
        {
            static EventCollector collector;
            return collector;
        }

        int Execute( int argc, char * argv[] )
        {
            Options options;
            if( !options.Parse( argc, argv  ))
            {
                return -1;
            }

            m_OriginalTimeStamps = options.GetOriginalTs();
            CreateLogger( );

            stringstream ss;
            ss << "Event collector " << VERSION_MAJOR << "." << VERSION_MINOR << " " << BUILD_DATE  << " "<< BUILD_TIME;
            m_Logger->LogInfo( ss.str( ) );

            if( !ReadNgnmsHomeEnvVariable( ) )
            {
                return -2;
            }

            SetupLogFile( options );

            if( !CreateDbStorage( options ) )
            {
                return -3;
            }

            CreateEventDecorator( );
           

            if( !CreateClassifier( options ))
            {
                return -4;
            }

            CreateParser( options );

            CreateDataProvider( options );

            MessageLoop( options );
            return 0;
        }

    private:
        static void SigIntHandler( int signum )
        {
            GetInstance( ).m_Logger->LogInfo( "" );
            GetInstance( ).m_Logger->LogInfo( "Termination by SIGINT!" );

            EventCollector::GetInstance( ).m_DataProvider->Stop( );
        }

    private:
        EventCollector( ):
        m_OriginalTimeStamps(false),
        m_Debug( false )
        {

        }

        void CreateLogger( )
        {
            m_Logger = shared_ptr<Logger>( new Logger( ) );
        }

        void SetupLogFile( Options& Options )
        {
            string logFileName = Options.GetLogFileName( );

            if( '/' != logFileName[0]  )
            {
                logFileName = m_NgnmsHomePath + logFileName;
            }

            m_Logger->SetLogFileName( logFileName );
        }

        void MessageLoop( Options& Options )
        {
            // Bind signal to Ctrl-C in order to terminate message loop
            signal( SIGINT, SigIntHandler );

            if( !m_DataProvider->Run( ) )
            {
                switch( Options.GetSourceType() )
        		{
        			case Options::SourceType::SYSLOG_FILE:
        			case Options::SourceType::SYSLOG_FILE_POLLING:
        			case Options::SourceType::SNMP_FILE:
        			case Options::SourceType::SNMP_FILE_POLLING:
    				case Options::SourceType::APACHE_FILE:
    				case Options::SourceType::APACHE_FILE_POLLING:
    				case Options::SourceType::CUSTOM1_FILE:
    				case Options::SourceType::CUSTOM1_FILE_POLLING:
                    case Options::SourceType::CAN_BUS_FILE:
    				case Options::SourceType::CAN_BUS_FILE_POLLING:
        				m_Logger->LogError( "Can't open input file!" );
        			break;

        			break;
        			case Options::SourceType::SYSLOG_UDP:
        			case Options::SourceType::SYSLOG_TCP:
        			case Options::SourceType::NETFLOW_UDP:
        			case Options::SourceType::NETFLOW_TCP:
        				m_Logger->LogError( "Permission denied or port busy!" );
        			break;
        		}
            }
        }

        bool ReadNgnmsHomeEnvVariable( )
        {
            char *ngnmsHome = getenv ( HOME_ENV.c_str() );
            if( nullptr == ngnmsHome )
            {
                m_Logger->LogInfo( "NGNMS_HOME variable is not set" );
                return true;
            }

            m_NgnmsHomePath = ngnmsHome;
            if( m_NgnmsHomePath[0] != '/' )
            {
                stringstream ss;
                ss << "Wrong setting NGNMS_HOME = " << m_NgnmsHomePath;
                m_Logger->LogError( ss.str( ) );

                return false;
            }

            fs::path data_dir( m_NgnmsHomePath );
            if( !fs::is_directory( data_dir ) )
            {
                stringstream ss;
                ss << "Should contain directory NGNMS_HOME = " << m_NgnmsHomePath;
                m_Logger->LogError( ss.str( ) );

                return false;
            }

            if( !fs::exists( data_dir ) )
            {
                stringstream ss;
                ss << "Directory not exist NGNMS_HOME = " << m_NgnmsHomePath;
                m_Logger->LogError( ss.str( ) );

                return false;
            }

            if( '/' != m_NgnmsHomePath[ m_NgnmsHomePath.length() - 1 ] )
            {
                m_NgnmsHomePath += '/';
            }

            stringstream ss;
            ss << "NGNMS_HOME = " << m_NgnmsHomePath;

            m_Logger->LogInfo( ss.str( ) );

            return true;
        }

        bool CreateClassifier( Options& Options )
        {
            string RuleFileName = Options.GetRuleFileName( );
            if( '/' != RuleFileName[0]  )
            {
                RuleFileName = m_NgnmsHomePath + RuleFileName;
            }

            if( !boost::filesystem::exists( RuleFileName ) )
            {
                stringstream ss;
                ss << "Rule file not exist! Path = " << RuleFileName;

                m_Logger->LogError( ss.str( ) );
                return false;
            }

            stringstream ss;
            ss << "Rule File = " << RuleFileName;
            m_Logger->LogInfo( ss.str( ) );

            m_Classifier = shared_ptr<IClassifier>(new Classifier(Options.GetDebug( ), m_EventDecorator ));

            switch( m_Classifier->Initialize( RuleFileName ) )
            {
                case IClassifier::ResultCodes::RESULT_CODE_OK:
                    break;
                case IClassifier::ResultCodes::RESULT_CODE_CANT_OPEN_FILE:
                    m_Logger->LogError( "Rule file not exist!" );
                    return false;
                case IClassifier::ResultCodes::RESULT_CODE_PARSE_ERROR:
                    m_Logger->LogError( "Can't parse rule file!" );
                    return false;
            }

            m_Classifier->RegisterListener( *this );
            return true;
        }

        void CreateDataProvider( Options& Options )
        {
            switch( Options.GetSourceType() )
            {
				case Options::SourceType::SYSLOG_FILE:
					 m_DataProvider = shared_ptr<IDataProvider>( new SyslogFileDP( Options.GetFileName( ) ) );
				break;
				case Options::SourceType::SYSLOG_FILE_POLLING:
		             m_DataProvider =  shared_ptr<IDataProvider>( new SyslogFilePollingDP( Options.GetFileName( ) , m_Logger) );
				break;
				case Options::SourceType::SYSLOG_UDP:
					 m_DataProvider = shared_ptr<IDataProvider>( new SyslogUdpDP( Options.GetPort( ), Options.GetBindIPAddress() ) );
				break;
				case Options::SourceType::SYSLOG_TCP:
					m_DataProvider =  shared_ptr<IDataProvider>( new SyslogTcpDP( Options.GetPort( ), Options.GetBindIPAddress( ) ) );
				break;
				case Options::SourceType::SNMP_FILE:
					 m_DataProvider = shared_ptr<IDataProvider>( new SyslogFileDP( Options.GetFileName( ) ) );
				break;
				case Options::SourceType::SNMP_FILE_POLLING:
		             m_DataProvider =  shared_ptr<IDataProvider>( new SyslogFilePollingDP( Options.GetFileName( ), m_Logger ) );
				break;
				case Options::SourceType::NETFLOW_UDP:
					m_DataProvider =  shared_ptr<IDataProvider>( new NetFlowUdpDP( Options.GetPort( ) , Options.GetBindIPAddress( ) ) );
				break;
				case Options::SourceType::NETFLOW_TCP:
					m_DataProvider = shared_ptr<IDataProvider>( new NetFlowTcpDP( Options.GetPort( ) , Options.GetBindIPAddress( )  ) );
				break;
				case Options::SourceType::APACHE_FILE:
					 m_DataProvider = shared_ptr<IDataProvider>( new ApacheFileDP( Options.GetFileName( ) ) );
				break;
				case Options::SourceType::APACHE_FILE_POLLING:
		             m_DataProvider =  shared_ptr<IDataProvider>( new ApacheFilePollingDP( Options.GetFileName( ), m_Logger ) );
				break;
				case Options::SourceType::CUSTOM1_FILE:
					 m_DataProvider = shared_ptr<IDataProvider>( new ApacheFileDP( Options.GetFileName( ) ) );
				break;
				case Options::SourceType::CUSTOM1_FILE_POLLING:
					m_DataProvider =  shared_ptr<IDataProvider>( new ApacheFilePollingDP( Options.GetFileName( ) , m_Logger ) );
				break;
				case Options::SourceType::CUSTOM2_FILE:
					m_DataProvider = shared_ptr<IDataProvider>( new ApacheFileDP( Options.GetFileName( ) ) );
				break;
				case Options::SourceType::CUSTOM2_FILE_POLLING:
					m_DataProvider =  shared_ptr<IDataProvider>( new ApacheFilePollingDP( Options.GetFileName( ) , m_Logger ) );
				break;
                case Options::SourceType::CAN_BUS_FILE:
					m_DataProvider = shared_ptr<IDataProvider>( new ApacheFileDP( Options.GetFileName( ) ) );
				break;
				case Options::SourceType::CAN_BUS_FILE_POLLING:
					m_DataProvider =  shared_ptr<IDataProvider>( new ApacheFilePollingDP( Options.GetFileName( ) , m_Logger ) );
				break;
            }

            m_DataProvider->RegisterListener( *this );
        }

        void CreateParser( Options& Options )
        {
            switch( Options.GetSourceType() )
			{
				case Options::SourceType::SYSLOG_FILE:
				case Options::SourceType::SYSLOG_FILE_POLLING:
				case Options::SourceType::SYSLOG_UDP:
				case Options::SourceType::SYSLOG_TCP:
					m_Parser = shared_ptr<IParser>( new ParserSyslog( ) );
				break;
				case Options::SourceType::SNMP_FILE:
				case Options::SourceType::SNMP_FILE_POLLING:
					m_Parser = shared_ptr<IParser>( new SnmpParser( ) );
				break;
				case Options::SourceType::NETFLOW_UDP:
					m_Parser = shared_ptr<IParser>( new NetFlowParser( ) );
				break;
				case Options::SourceType::NETFLOW_TCP:
					m_Parser = shared_ptr<IParser>( new NetFlowParser( ) );
				break;
				case Options::SourceType::APACHE_FILE:
				case Options::SourceType::APACHE_FILE_POLLING:
					m_Parser = shared_ptr<IParser>( new ApacheParser( ) );
				break;

				case Options::SourceType::CUSTOM1_FILE:
				case Options::SourceType::CUSTOM1_FILE_POLLING:
					m_Parser = shared_ptr<IParser>( new Custom1Parser( ) );
				break;
				case Options::SourceType::CUSTOM2_FILE:
				case Options::SourceType::CUSTOM2_FILE_POLLING:
					m_Parser = shared_ptr<IParser>( new Custom2Parser( ) );
				break;
                case Options::SourceType::CAN_BUS_FILE:
				case Options::SourceType::CAN_BUS_FILE_POLLING:
					m_Parser = shared_ptr<IParser>( new CANParser( ) );
				break;
			}

            m_Parser->RegisterListener( *this );
        }

        bool CreateDbStorage( Options& Options )
        {
            m_Database = shared_ptr<Database>( new Database( Options.GetDebug( ) ) );

            DbSettings dbSettings;

            string dbSettingsFileName = Options.GetDbSettingsFileName( );
            if( '/' != dbSettingsFileName[0]  )
            {
                dbSettingsFileName = m_NgnmsHomePath + dbSettingsFileName;
            }

            if( !boost::filesystem::exists( dbSettingsFileName ) )
            {
                stringstream ss;
                ss << "DB settings file not exist! Path = " << dbSettingsFileName;
                m_Logger->LogError( ss.str( ) );
                return false;
            }

            stringstream ss;
            ss << "DB Settings File = " << dbSettingsFileName;
            m_Logger->LogInfo( ss.str( ) );
            if( !dbSettings.FillFromFile( dbSettingsFileName ) )
            {
                m_Logger->LogError( "Failed to read DB configuration file!" );
                return false;
            }

            bool connected = false;
            for( int i = 0; i < dbSettings.GetTimeout(); ++i )
            {
                if( !m_Database->Connect( dbSettings ) )
                {
                    sleep( 1 );
                    continue;
                }
                else
                {
                    connected = true;
                    break;
                }
            }

            if( !connected )
            {
                m_Logger->LogError( "Can't establish connection to the DB!" );
                return false;
            }

            if(Options.GetRenewTables())
            {
            	m_Database->DeleteTables();
            }

            return m_Database->CreateTables();
        }

        void CreateEventDecorator()
        {
            m_EventDecorator = make_shared<EventDecorator>(m_Database);
        }

        void Notify( ClassifierEvent& event )
        {
            if( event.GetDiscard() )
            {
                return;
            }
            
            DbReturnCode rc = m_Database->WriteEvent( event.GetEvent( ) );
            if( rc.IsFail( ) )
            {
                m_Logger->LogError( rc.GetDetails() );
                m_DataProvider->Stop( );
                return;
            }

            if( "" != event.GetActionScript() )
            {
                string actionSctipt = event.GetActionScript();
                if( '/' != actionSctipt[0]  )
                {
                    actionSctipt = m_NgnmsHomePath + actionSctipt;
                }

                if( m_Debug )  /* Turn on by debug option */
                {
                    stringstream ss;
                    ss << "Exectute Script = " << actionSctipt << endl;
                    ss << "Severity        = " << event.GetEvent( ) .getSeverity() << endl;
                    ss << "Priority        = " << event.GetEvent( ).getPriority().c_str( ) << endl;
                    ss << "TimeStamp       = " << event.GetEvent( ).getTs().c_str( ) << endl;
                    ss << "Origin          = " << event.GetEvent( ).getOrigin().c_str( ) << endl;
                    ss << "Facility        = " << event.GetEvent( ).getFacility().c_str( ) << endl;
                    ss << "Code            = " << event.GetEvent( ).getCode().c_str( ) << endl;
                    ss << "Description     = " << event.GetEvent( ).getDescr().c_str( ) << endl;
                    m_Logger->LogDebug( ss.str( ) );
                }

                if( boost::filesystem::exists( actionSctipt ) )
                {
                	Triggers::Execute( actionSctipt, event.GetEvent( ) );
                }
                else
                {
                    stringstream ss;
                    ss << "Action script not exist! Path = " << actionSctipt;
                    m_Logger->LogError( ss.str( ) );
                }
            }
        }

        void Notify( DataProviderListener::DataProviderEvent& data )
        {
            if( DataProviderListener::DataProviderEvent::Event::DATA == data.GetEvent() )
            {
                if( m_Debug )  /* Turn on by debug option */
                {
                    if( data.GetHasSourceIP( ) )
                    {
                        stringstream ss;
                        ss << "SourceIP = " <<  data.GetSourceIPAddress( ) << endl;
                        m_Logger->LogDebug( ss.str( ) );
                    }

                    stringstream ss;
                    ss << "Message = " << data.GetData( ) << endl;
                    m_Logger->LogDebug( ss.str( ) );
                }

                m_Parser->Parse( data.GetData( ), data.GetHasSourceIP( ), data.GetSourceIPAddress( ) );
            }

            if( DataProviderListener::DataProviderEvent::Event::END_OF_DATA == data.GetEvent() )
            {
                m_Parser->ProcessEndOfData( );
            }

            if( DataProviderListener::DataProviderEvent::Event::SOURCE_ATTACHED == data.GetEvent() )
            {
                if( data.GetHasSourceIP( ) )
                {
                	m_Parser->SourceAttached(data.GetSourceIPAddress( ));
                }
            }

            if( DataProviderListener::DataProviderEvent::Event::SOURCE_DETTACHED == data.GetEvent() )
            {
                if( data.GetHasSourceIP( ) )
                {
                	m_Parser->SourceDetached(data.GetSourceIPAddress( ));
                }
            }
        }

        void Notify( Event& event )
        {
        	if(m_OriginalTimeStamps)
        	{
        		event.setTs( event.getOrign_Ts());
        	}

            m_Classifier->Classify( event );
        }

    private:
        shared_ptr<EventDecorator>  m_EventDecorator;
        shared_ptr<IClassifier>     m_Classifier;
        shared_ptr<IDataProvider>   m_DataProvider;
        shared_ptr<IParser>         m_Parser;
        shared_ptr<Database>        m_Database;
        shared_ptr<Logger>          m_Logger;
        bool                        m_OriginalTimeStamps;
        bool                        m_Debug;
        string                      m_NgnmsHomePath;
};

int main( int argc, char * argv[] )
{
    try
    {
        EventCollector::GetInstance( ).Execute( argc, argv );
    }
    catch( const exception &e )
    {
        cerr << "Main thread Exception = " << e.what( ) << endl;
    }
    catch( ... )
    {
        cerr << "Main thread Unknown exception!" << endl;
    }
}
