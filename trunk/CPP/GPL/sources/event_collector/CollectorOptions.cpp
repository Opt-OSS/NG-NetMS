#include "CollectorOptions.h"
#include <iostream>
#include <map>

CollectorOptions::CollectorOptions( ):
m_CollectorType( CollectorType::SYSLOG ),
m_DataSource( DataSource::FILE ),
m_FileName( "/var/log/syslog" ),
m_LogFileName( "ngnms_collector.log" ),
m_RuleFileName( "rules.txt" ),
m_DbSettingsFileName( "db.cfg" ),
m_Port( 514 ),
m_Debug( false )
{

}

bool CollectorOptions::Parse( vector<string>& Arguments )
{
    vector<Option> options;
    Option optionC( "-c", true );
    Option optionF( "-f", true );
    Option optionI( "-i", true );
    Option optionS( "-s", false );
    Option optionU( "-u", false );
    Option optionT( "-t", false );
    Option optionP( "-p", true );
    Option optionO( "-o", true );
    Option optionV( "-v", false );
    Option optionH( "-h", false );
    Option optionR( "-r", true );
    Option optionL( "-l", true );

    options.push_back( optionC );
    options.push_back( optionF );
    options.push_back( optionI );
    options.push_back( optionS );
    options.push_back( optionU );
    options.push_back( optionT );
    options.push_back( optionP );
    options.push_back( optionO );
    options.push_back( optionV );
    options.push_back( optionH );
    options.push_back( optionR );
    options.push_back( optionL );

    if( !CheckForIlligalOptions( Arguments, options ))
    {
        ShowUsage( cerr );
        return false;
    }

    int mutialOptions = 0;
    if( IsOptionExist( Arguments, optionI ) )
    {
        mutialOptions++;
    }

    if( IsOptionExist( Arguments, optionF ) )
    {
        mutialOptions++;
    }

    if( IsOptionExist( Arguments, optionS ) )
    {
        mutialOptions++;
    }

    if( IsOptionExist( Arguments, optionU ) )
    {
        mutialOptions++;
    }

    if( IsOptionExist( Arguments, optionT ) )
    {
        mutialOptions++;
    }

    if( mutialOptions > 1 )
    {
        ShowUsage( cerr );
        return false;
    }

    if( !CheckOptionDublication( Arguments ) )
    {
        ShowUsage( cerr );
        return false;
    }

    // Check help option
    if( IsOptionExist( Arguments, optionH ) )
    {
        ShowUsage( cerr );
        return false;
    }

    if( IsOptionExist( Arguments, optionV ) )
    {
        m_Debug = true;
    }

    if( IsOptionExist( Arguments, optionS ) )
    {
        m_DataSource = DataSource::STDIN;
    }

    if( IsOptionExist( Arguments, optionU ) )
    {
        m_DataSource = DataSource::UDP;
    }

    if( IsOptionExist( Arguments, optionT ) )
    {
        m_DataSource = DataSource::TCP;
    }

    if( IsOptionExist( Arguments, optionF ) )
    {
        m_FileName   = GetOptionValue( Arguments, optionF );
        m_DataSource = DataSource::FILE;
    }

    if( IsOptionExist( Arguments, optionI ) )
    {
        m_FileName   = GetOptionValue( Arguments, optionI );
        m_DataSource = DataSource::FILE_POLLING;
    }

    if( IsOptionExist( Arguments, optionO ) )
    {
        m_DbSettingsFileName = GetOptionValue( Arguments, optionO );
    }

    if( IsOptionExist( Arguments, optionL ) )
    {
        m_LogFileName = GetOptionValue( Arguments, optionL );
    }

    if( IsOptionExist( Arguments, optionP ) )
    {
        stringstream ss;
        string portStr;
        ss << GetOptionValue( Arguments, optionP );
        ss >> portStr;

        if( portStr.size() > 5 ) // Too long
        {
            ShowUsage( cerr );
            return false;
        }

        for( auto c : portStr ) // Check for number
        {
            if ( !isdigit( c ) )
            {
                ShowUsage( cerr );
                return false;
            }
        }

        stringstream ssi;
        ssi << portStr;
        ssi >> m_Port;
    }

    if( IsOptionExist( Arguments, optionC ) )
    {
        string value = GetOptionValue( Arguments, optionC );

        if( "syslog" == value )
        {
            m_CollectorType = CollectorType::SYSLOG;
        }
        else if( "snmp" == value )
        {
            m_CollectorType = CollectorType::SNMP;
        }
        else
        {
            ShowUsage( cerr );
            return false;
        }
    }

    if( IsOptionExist( Arguments, optionR ) )
    {
        m_RuleFileName = GetOptionValue( Arguments, optionR );
    }

    return true;
}

CollectorOptions::CollectorType CollectorOptions::GetCollectorType( )
{
    return m_CollectorType;
}

CollectorOptions::DataSource CollectorOptions::GetDataSource( )
{
    return m_DataSource;
}

string  CollectorOptions::GetFileName( )
{
    return m_FileName;
}

string CollectorOptions::GetRuleFileName( )
{
    return m_RuleFileName;
}

string CollectorOptions::GetDbSettingsFileName( )
{
    return m_DbSettingsFileName;
}

string CollectorOptions::GetLogFileName( )
{
    return m_LogFileName;
}

int CollectorOptions::GetPort( )
{
    return m_Port;
}

bool CollectorOptions::GetDebug( )
{
    return m_Debug;
}

bool CollectorOptions::CheckForIlligalOptions( vector<string>& Arguments, vector<Option>& Options )
{
    size_t argumentIndex = 0;
    for( string& argument : Arguments )
    {
        if( '-' == argument[0] )
        {
            bool found = false;
            for( auto& option : Options )
            {
                if( argument == option.GetName( ) )
                {
                    found = true;
                    if( option.GetHasValue( ) )
                    {
                        if( argumentIndex + 1 == Arguments.size( ) )
                        {
                           return false;
                        }

                        if( '-' == Arguments[argumentIndex + 1 ][0] )
                        {
                           return false;
                        }
                    }
                    else
                    {
                        if( argumentIndex + 1 != Arguments.size( ) )
                        {
                            if( '-' != Arguments[argumentIndex + 1 ][0] )
                            {
                                return false;
                            }
                        }
                    }

                    break;
                }
            }

            if( !found )
            {
                return false;
            }
        }

        argumentIndex++;
    }

    return true;
}

bool CollectorOptions::IsOptionExist( vector<string>& Arguments, Option& option )
{
    for( string& argument : Arguments )
    {
        if( '-' == argument[0] )
        {
            if( argument == option.GetName( ) )
            {
                return true;
            }
        }
    }

    return false;
}

string CollectorOptions::GetOptionValue( vector<string>& Arguments, Option& option )
{
    size_t argumentIndex = 0;
    for( string& argument : Arguments )
    {
         if( '-' == argument[0] )
         {
             if( argument == option.GetName( ) )
             {
                 if( argumentIndex + 1 == Arguments.size( ) )
                 {
                      return string( "" );
                 }

                 return Arguments[argumentIndex + 1];
             }
         }

         argumentIndex++;
     }

     return string( "" );
}

bool CollectorOptions::CheckOptionDublication( vector<string> Arguments )
{
    map<string, int> argumetsCount;
    for( string& argument : Arguments )
    {
        if( '-' != argument[0] )
        {
            continue;
        }

        argumetsCount[argument]++;
    }

    for( auto& entry : argumetsCount )
    {
        if( entry.second > 1 )
        {
            return false;
        }
    }

    return true;
}

void CollectorOptions::ShowUsage( ostream& Stream )
{
    Stream << "Usage: ngnm_collector [-c snmp/syslog] [-f/-i/-s/-u/-t] [-o] [-p] [-v] [-h] [-l]" << endl;
    Stream << " -c  collect snmp or syslog. Default is syslog" << endl;
    Stream << " -f  Process data from file. Default is /var/log/syslog" << endl;
    Stream << " -i  Process data from file (infinite). Default is /var/log/syslog" << endl;
    Stream << " -r  Rule file location. Default is rule.txt" << endl;
    Stream << " -o  Configuration file with encrypted data base options. Default is ./db.cfg" << endl;
    Stream << " -s  Process data from STDIN" << endl;
    Stream << " -u  Process data received by UDP" << endl;
    Stream << " -t  Process data received by TCP" << endl;
    Stream << " -p  Port for UDP/TCP. Default is 514" << endl;
    Stream << " -v  Verbose debug messages" << endl;
    Stream << " -l  Log file location. Default is ./ngnms_collector.log" << endl;
    Stream << " -h  This help screen" <<endl;
}
