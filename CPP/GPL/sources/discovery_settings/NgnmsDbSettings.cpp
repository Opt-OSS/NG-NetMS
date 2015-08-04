#include <boost/program_options/options_description.hpp>
#include <boost/program_options/parsers.hpp>
#include <boost/program_options/variables_map.hpp>
#include <boost/tokenizer.hpp>
#include <boost/token_functions.hpp>

using namespace boost;
using namespace boost::program_options;

#include <iostream>
#include <fstream>
#include <exception>
#include "DiscoverySettings.h"
#include "DbSettings.h"
#include "DbConnector.h"
#include "Database.h"
#include "Configuration.h"

class NgnmsDiscoverySettings
{
    public:
        NgnmsDiscoverySettings( )
        {

        }

        void Execute( int argc, char * argv[] )
        {
            cout << "Discovery Settings " << VERSION_MAJOR << "." << VERSION_MINOR << " " << BUILD_DATE  << " "<< BUILD_TIME << endl;

             try
             {
                 options_description desc( "Program Usage", 1024, 512 );

                 desc.add_options()
                                ( "help",     "produce help message")
                                ( "seed-host,h",       value<string>(&m_SeedHosts),             "Seed Host" )
                                ( "user,u",            value<string>(&m_UserName),              "User for seed host" )
                                ( "password,p",        value<string>(&m_Password),              "Password for seed host" )
                                ( "enable-password,e", value<string>(&m_EnablePassword),        "Enable password (Cisco only)" )
                                ( "ro-community,r",    value<string>(&m_SnmpReadCommunity),     "SNMP v1/2 Read-Only Community"  )
                                ( "host-type,t",       value<string>(&m_HostType),              "Juniper/Cisco" )
                                ( "access,a",          value<string>(&m_Access),                "SSH/Telnet" )

                 ;

                 variables_map vm;
                 store(parse_command_line(argc, argv, desc), vm);

                 if( vm.count( "help" ) )
                 {
                     std::cout << desc << "\n";
                     return;
                 }

                 notify( vm );
             }
             catch( std::exception& e )
             {
                 std::cerr << "Error: " << e.what() << "\n";
                 return;
             }
             catch(...)
             {
                 std::cerr << "Unknown error!" << "\n";
                 return;
             }

             // Check string parameters
             if( m_HostType.length( ) )
             {
                 if( "Juniper" != m_HostType && "Cisco" != m_HostType )
                 {
                     cout << "Error: Wrong host type (" << m_HostType << ") Permitted only Juniper/Cisco" << endl;
                     return;
                 }
             }
             else
             {
                 m_HostType = "Juniper";
                 cout << "Warning: Host type is empty and default host type is used (Juniper)" << endl;
             }

             if( m_Access.length( ) )
             {
                 if( "Telnet" != m_Access && "SSH" != m_Access )
                 {
                     cout << "Error: Wrong access type (" << m_Access << ") Permitted only Telnet/SSH" << endl;
                     return;
                 }
             }
             else
             {
                 m_Access = "SSH";
                 cout << "Warning: Access type is empty and default access type is used (SSH)" << endl;
             }

             // Read Database access settings
             DbSettings dbSettings;
             if( !dbSettings.FillFromFile( DB_CFG_FILE_NAME  ) )
             {
                 cout << "Error: File (" << DB_CFG_FILE_NAME  << ")not found!" << endl;
                 return;
             }

             // Test connectivity to the database
             DbConnector connector( dbSettings );
             DbReturnCode rc = connector.Connect( );
             if( rc.IsFail( ) )
             {
                 cout << "Error: Database connection: Failed!" << endl;
                 return;
             }

             DiscoverySettings discoverySettings( m_SeedHosts, m_UserName, m_Password, m_EnablePassword, m_SnmpReadCommunity, m_HostType, m_Access );

             Database database;
             database.Connect( dbSettings );
             rc = database.SetDiscoverySettings( discoverySettings );
             if( rc.IsFail( ) )
             {
                 cout << "Error: Discovery settings saving: Failed!" << endl;
                 cout << "Details: " << rc.GetDetails( ) << endl;
                 return;
             }

             cout << "Discovery settings stored: Successfully!" << endl;
        }

        static NgnmsDiscoverySettings& GetInstance( )
        {
            static NgnmsDiscoverySettings instance;
            return instance;
        }

    private:
        string                  m_SeedHosts;
        string                  m_UserName;
        string                  m_Password;
        string                  m_EnablePassword;
        string                  m_SnmpReadCommunity;
        string                  m_HostType;
        string                  m_Access;
};

int main( int argc, char * argv[] )
{
    NgnmsDiscoverySettings::GetInstance( ).Execute( argc, argv );
}
