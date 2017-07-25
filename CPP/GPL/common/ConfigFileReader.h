#pragma once

#include <string>
#include <fstream>
#include <map>
#include "TimeInterval.h"

using namespace std;

class ConfigFileReader
{
    public:
        ConfigFileReader( string FileName );
        bool GetParameter( string Name , bool& Value );
        bool GetParameter( string Name, string& Value );
        bool GetParameter( string Name, unsigned int& Value );
        bool GetParameter( string Name, TimeInterval& Value );

    private:
        string			m_FileName;
        fstream			m_FileStream;
        map<string,string>      m_Parameters;
};
