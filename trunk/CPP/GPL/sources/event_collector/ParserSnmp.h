#pragma once

#include "IParser.h"
#include <string>

using namespace std;

class SnmpTimestampParser;

class ParserSnmp: public IParser
{
    public:
        ParserSnmp( );
        virtual ~ParserSnmp();
        bool Parse( string Message, bool HasSourceIp, string SourceIP );
        bool ProcessEndOfData( );
        void RegisterListener( ParserListener &Listener );
        void UnregisterListener( ParserListener &Listener );

    private:
        string Time2String( time_t time );
        string GetTimestamp( SnmpTimestampParser& TimestampParser );
        string GetTimeZone( );
        int GetInteger( string String );
        string CreateTimestamp( int Year, int Month, int Day, int Hours, int Minutes, int Seconds );

    private:
        string  m_Host;
        string  m_TimeStamp;
        string  m_AcumulatedMessage;
        Notifier<ParserListener, Event> m_Notifier;
};


