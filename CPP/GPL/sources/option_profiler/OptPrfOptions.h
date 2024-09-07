#pragma once

#include <vector>
#include <string>
#include <sstream>

using namespace std;

class OptPrfOptions
{
    public:
        OptPrfOptions( );
        bool Parse( int argc, char * argv[] );

        string GetOptionsFile( );
        bool   GetDrop( );
        bool   GetDebug( );
        string GetLogFile( );

    private:
        string          m_OptionsFile;
        bool            m_Drop;
        bool            m_Debug;
        string          m_LogFile;
};
