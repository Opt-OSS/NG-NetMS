#include "SnmpObserver.h"
#include "ObserverOptions.h"
#include "OriginManager.h"
#include "Database.h"
#include "LogWriter.h"
#include "Initializer.h"

#include <chrono>		//chrono::steady_clock::time_poin
#include <thread>		
#include <ctime>		
#include <boost/filesystem/operations.hpp>

using std::shared_ptr;

namespace fs = boost::filesystem;

SnmpObserver& SnmpObserver::GetInstance()
{
    static SnmpObserver observer;
    return observer;
}

int SnmpObserver::Execute( int argc, char * argv[] )
{
    ObserverOptions options;
    if( !ParseCmdLineArgs( options, argc, argv ) )
    {
        return -1;
    }

    CreateLogger(options);

    stringstream ss;
    ss << "Event Observer " << VERSION_MAJOR << "." << VERSION_MINOR << " " << BUILD_DATE  << " "<< BUILD_TIME;
    m_Logger->LogInfo( ss.str( ) );

    if( !ReadNgnmsHomeEnvVariable( ) )
    {
        return -2;
        }

    if( CreateDbStorage( options ) )
      {
      m_Logger->LogInfo( "Db connected..." );
      }
      else 
        {
        return -3;
        }
   
    if( Update(options) )
      {
      m_Logger->LogInfo( "Db updated..." );
      }
      else
       {
        return -4;
       }


    if(CreateOriginManager(options) )
      {
      m_Logger->LogInfo( "Origin manager created..." );
      }
      else
       {  
        return -5;
       }

    Run( options );
    return 0;
}

SnmpObserver::SnmpObserver( ):
    m_Debug( false )
{
}

void SnmpObserver::CreateLogger(ObserverOptions& Options)
{
    m_Logger = shared_ptr<LogWriter>( new LogWriter( ) );
    m_Logger->SetLogLevel(Options.GetVerbose());
    string logFileName = Options.GetLogFileName( );

    if( '/' != logFileName[0] )
    {
        logFileName = m_NgnmsHomePath + logFileName;
    }

    m_Logger->SetLogFileName( logFileName );
}

bool SnmpObserver::CreateOriginManager( ObserverOptions& options )
{
    m_Observer = unique_ptr<OriginManager>( new OriginManager(m_Database, m_Logger, options.GetMaxInterval()));
    m_Logger->LogInfo("In Create Origin Manager");
    return m_Observer->LoadOrigins();
}

bool SnmpObserver::ParseCmdLineArgs( ObserverOptions& Options, int argc, char * argv[] )
{
    if( !Options.Parse(argc, argv) )
    {
        return false;
    }

    return true;
}

bool SnmpObserver::ReadNgnmsHomeEnvVariable( )
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
        ss << "Wrong setting for NGNMS_HOME = " << m_NgnmsHomePath;
        m_Logger->LogError( ss.str( ) );

        return false;
    }

    fs::path data_dir( m_NgnmsHomePath );
    if( !fs::is_directory( data_dir ) )
    {
        stringstream ss;
        ss << "Home path variable should contain directory NGNMS_HOME = " << m_NgnmsHomePath;
        m_Logger->LogError( ss.str( ) );

        return false;
    }

    if( !fs::exists( data_dir ) )
    {
        stringstream ss;
        ss << "Directory does not exist NGNMS_HOME = " << m_NgnmsHomePath;
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

bool SnmpObserver::CreateDbStorage( ObserverOptions& Options )
{
    m_Database = shared_ptr<Database>( new Database(m_Logger, Options.GetMDef()) );

    DbSettings dbSettings;

    string dbSettingsFileName = Options.GetDbSettingsFileName( );
    if( '/' != dbSettingsFileName[0]  )
    {
        dbSettingsFileName = m_NgnmsHomePath + dbSettingsFileName;
    }

    if( !boost::filesystem::exists( dbSettingsFileName ) )
    {
        stringstream ss;
        ss << "DB settings file does not exist! Path = " << dbSettingsFileName;
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
    for (int i = 0; i < 10; ++i) {
        if (!m_Database->Connect(dbSettings)) {

            sleep(1);
            continue;
        } else {
            connected = true;
            break;
        }
    }

    if (!connected) {
        m_Logger->LogError("Can't establish connection to the DB!");
        return false;
    }

    if (!m_Database->LoadDatabaseKey())
        return false;

    return true;
}

bool SnmpObserver::Update(ObserverOptions& options)
{
    Initializer i(m_Database, options.GetConfigFileName());
    if( options.GetDrop( ) )
    {
        if( !i.DropTables( ) )
        {
            return false;
        }
    }
    
    if( !i.CreateTables( ) )
    {
        return false;
    }

    if( options.GetUpdate( ) )
    {
        return i.Update( );
    }
    
    return true;
}

void SnmpObserver::Run( ObserverOptions& options )
{
    m_Observer->LoadOriginThreads();
    m_Logger->LogInfo( "Origin threads loaded..." );
    m_Observer->Run();
}

