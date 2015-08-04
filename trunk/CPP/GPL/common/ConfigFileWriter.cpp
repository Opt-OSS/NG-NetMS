#include "ConfigFileWriter.h"
#include <sstream>

ConfigFileWriter::ConfigFileWriter( string FileName ):
m_FileName( FileName )
{
    try { m_FileStream.open ( m_FileName, std::fstream::out ); } catch( ... ) { }
}

ConfigFileWriter::~ConfigFileWriter( )
{
    try { m_FileStream.close( ); } catch( ... ) { }
}

bool ConfigFileWriter::AddPrameter( string Name, const string &Value  )
{
    if( !m_FileStream.is_open( ) )
    {
        return false;
    }

    try { m_FileStream << Name << "=" << Value << endl; } catch( ... ) 	{ return false; }
    return true;
}

bool ConfigFileWriter::AddPrameter( string Name, bool Value )
{
    string value = Value ? "true" : "false";
    return AddPrameter( Name, value );
}

bool ConfigFileWriter::AddPrameter( string Name, unsigned int Value )
{
    stringstream ss;
    ss << Value;
    string value = ss.str( );
    return AddPrameter( Name, value );
}

bool ConfigFileWriter::AddPrameter( string Name, const TimeInterval& Value )
{
    return AddPrameter( Name, Value.ToString( ) );
}
