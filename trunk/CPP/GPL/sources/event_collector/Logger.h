#pragma once

#include <string>

using namespace std;

class Logger
{
    public:
        Logger( );

        void SetLogFileName( string LogFile );
        void LogInfo( string Message );
        void LogDebug( string Message );
        void LogError( string Message );

    private:
        string m_LogFile;
};
