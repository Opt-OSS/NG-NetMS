#pragma once

#include <string>
#include <fstream>
#include "TimeInterval.h"

using namespace std;

class ConfigFileWriter
{
    public:
        ConfigFileWriter( string FileName );
        ~ConfigFileWriter( );
        bool AddPrameter( string Name, bool Value );
        bool AddPrameter( string Name, const  string &Value );
        bool AddPrameter( string Name, unsigned int Value );
        bool AddPrameter( string Name, const TimeInterval &Value );

    private:
        string  m_FileName;
        fstream m_FileStream;
};
