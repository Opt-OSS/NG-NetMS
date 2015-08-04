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
#include "CollectorOptions.h"

// Parsers
#include "ParserSyslog.h"
#include "ParserSnmp.h"

// Logger
#include "Logger.h"

// Data providers
#include "FileDataProvider.h"
#include "FilePollingDataProvider.h"
#include "TcpDataProvider.h"
#include "UdpDataProvider.h"
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
            CollectorOptions options;
            if( !ParseCmdLineArgs( options, argc, argv ) )
            {
                return -1;
            }

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

            CreateScriptExecutor( );

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
        m_Debug( false )
        {

        }

        void CreateLogger( )
        {
            m_Logger = shared_ptr<Logger>( new Logger( ) );
        }

        void SetupLogFile( CollectorOptions& Options )
        {
            string logFileName = Options.GetLogFileName( );

            if( '/' != logFileName[0]  )
            {
                logFileName = m_NgnmsHomePath + logFileName;
            }

            m_Logger->SetLogFileName( logFileName );
        }

        void MessageLoop( CollectorOptions& Options )
        {
            // Bind signal to Ctrl-C in order to terminate message loop
            signal( SIGINT, SigIntHandler );

            if( !m_DataProvider->Run( ) )
            {
                switch( Options.GetDataSource() )
                {
                    case CollectorOptions::DataSource::FILE:
                    case CollectorOptions::DataSource::STDIN:
                    case CollectorOptions::DataSource::FILE_POLLING:
                        m_Logger->LogError( "Can't open input file!" );
                    break;
                    case CollectorOptions::DataSource::UDP:
                    case CollectorOptions::DataSource::TCP:
                      m_Logger->LogError( "Permission denied or port busy!" );
                    break;
                }
            }
        }

        bool ParseCmdLineArgs( CollectorOptions& Options, int argc, char * argv[] )
        {
              vector<string> arguments;
              for( int i = 1; i < argc; ++i )
              {
                  arguments.push_back( argv[i] );
              }

              if( !Options.Parse( arguments ) )
              {
                  return false;
              }

              m_Debug = Options.GetDebug( );
              return true;
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

        bool CreateClassifier( CollectorOptions& Options )
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

            m_Classifier = shared_ptr<IClassifier>( new Classifier( Options.GetDebug( ) ));

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

        void CreateDataProvider( CollectorOptions& Options )
        {
            switch( Options.GetDataSource() )
            {
                case CollectorOptions::DataSource::FILE:
                    m_DataProvider = shared_ptr<IDataProvider>( new FileDataProvider( Options.GetFileName( ) ) );
                break;
                case CollectorOptions::DataSource::STDIN:
                    m_DataProvider = shared_ptr<IDataProvider>( new FileDataProvider( "/dev/stdin" ) );
                break;
                case CollectorOptions::DataSource::FILE_POLLING:
                    m_DataProvider =  shared_ptr<IDataProvider>( new FilePollingDataProvider( Options.GetFileName( ) ) );
                break;
                case CollectorOptions::DataSource::UDP:
                    m_DataProvider = shared_ptr<IDataProvider>( new UdpDataProvider( Options.GetPort( ) ) );
                break;
                case CollectorOptions::DataSource::TCP:
                  m_DataProvider =  shared_ptr<IDataProvider>( new TcpDataProvider( Options.GetPort( ) ) );
                break;
            }

            m_DataProvider->RegisterListener( *this );
        }

        void CreateParser( CollectorOptions& Options )
        {
            switch( Options.GetCollectorType( ) )
            {
                case CollectorOptions::CollectorType::SYSLOG:
                    m_Parser = shared_ptr<IParser>( new ParserSyslog( ) );
                break;
                case CollectorOptions::CollectorType::SNMP:
                    m_Parser = shared_ptr<IParser>( new ParserSnmp( ) );
                break;
            }

            m_Parser->RegisterListener( *this );
        }

        void CreateScriptExecutor( )
        {
            m_Triggers = shared_ptr<Triggers>( new Triggers( ) );
        }

        bool CreateDbStorage( CollectorOptions& Options )
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
            for( int i = 0; i < 1000; ++i )
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

            return true;
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
                    m_Triggers->Execute( actionSctipt, event.GetEvent( ) );
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
                    if( ! data.GetHasSourceIP( ) )
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
        }

        void Notify( Event& event )
        {
            m_Classifier->Classify( event );
        }

    private:
        shared_ptr<IClassifier>   m_Classifier;
        shared_ptr<IDataProvider> m_DataProvider;
        shared_ptr<IParser>       m_Parser;
        shared_ptr<Database>      m_Database;
        shared_ptr<Triggers>      m_Triggers;
        shared_ptr<Logger>        m_Logger;
        bool                      m_Debug;
        string                    m_NgnmsHomePath;
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
