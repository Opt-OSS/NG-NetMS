#include "ConfigFileReader.h"

ConfigFileReader::ConfigFileReader( string FileName ):
m_FileName( FileName )
{
    try
    {
        m_FileStream.open ( m_FileName, std::fstream::in );
        if( !m_FileStream.is_open( ) )
        {
            return;
        }

        while( !m_FileStream.eof() )
        {
            string line;
            getline( m_FileStream, line );

            size_t delipeter_position = line.find( "=" );
            if( string::npos == delipeter_position )
            {
                continue;
            }

            string name  = line.substr( 0, delipeter_position );
            string value = line.substr( delipeter_position+1, line.length( ) );
            m_Parameters[ name ] = value;
        }

        m_FileStream.close( );
    }
    catch( ... )
    {

    }
}

bool ConfigFileReader::GetParameter( string Name, string& Value )
{
    if( m_Parameters.end() == m_Parameters.find( Name ) )
    {
        return false;
    }

    Value = m_Parameters[Name];
    return true;
}

bool ConfigFileReader::GetParameter( string Name , bool& Value )
{
    string value;
    if( !GetParameter( Name, value ))
    {
        return false;
    }

    if( "true" == value )
    {
        Value = true;
        return true;
    }

    if( "false" == value )
    {
        Value = false;
        return true;
    }

    return false;
}

bool ConfigFileReader::GetParameter( string Name, unsigned int& Value )
{
    string value;
    if( !GetParameter( Name, value ))
    {
        return false;
    }

    stringstream ss;
    ss << value;
    ss >> Value;
    return true;
}

bool ConfigFileReader::GetParameter( string Name, TimeInterval& Value )
{
    string value;
    if( !GetParameter( Name, value ))
    {
        return false;
    }

    return Value.FillFromString( value );
}
