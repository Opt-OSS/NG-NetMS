#include "ParserSnmp.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "Event.h"
#include <time.h>

#include <vector>
#include <iostream>
#include <sstream>

class SnmpTimestampParser
{
    public:
        SnmpTimestampParser( ):
        m_Found( false )
        {

        }

        virtual ~SnmpTimestampParser()
        {

        }

        bool Parse( string Input )
        {
            m_Output = Input;
            if( 20 > Input.size() )
            {
                return false;
            }

            vector<size_t> numberIdxs;
            numberIdxs.push_back( 0 ); // Year
            numberIdxs.push_back( 1 );
            numberIdxs.push_back( 2 );
            numberIdxs.push_back( 3 );

            numberIdxs.push_back( 5 ); // Month
            numberIdxs.push_back( 6 );

            numberIdxs.push_back( 8 ); // Day
            numberIdxs.push_back( 9 );

            numberIdxs.push_back( 11 ); // Hour
            numberIdxs.push_back( 12 );

            numberIdxs.push_back( 14 ); // Minute
            numberIdxs.push_back( 15 );

            numberIdxs.push_back( 17 ); // Second
            numberIdxs.push_back( 18 );

            if( '-' != Input[4] || '-' != Input[7] || ' ' != Input[10] )
            {
                return false;
            }

            if( ':' != Input[13] || ':' != Input[16] )
            {
                return false;
            }

            for( auto numIdx : numberIdxs )
            {
                if( !IsNumber( Input[numIdx] ) )
                {
                    return false;
                }
            }

            Input = GetNumberString( Input, m_Year );
            Input = Input.substr( 1 );
            Input = GetNumberString( Input, m_Month );
            Input = Input.substr( 1 );
            Input = GetNumberString( Input, m_Day );
            Input = Input.substr( 1 );

            Input = GetNumberString( Input, m_Hours );
            Input = Input.substr( 1 );
            Input = GetNumberString( Input, m_Minutes );
            Input = Input.substr( 1 );
            Input = GetNumberString( Input, m_Seconds );
            Input = Input.substr( 1 );

            m_Output = Input;
            m_Found = true;
            return true;
        }

        string GetOutput( )
        {
            return m_Output;
        }

        bool GetFound( )
        {
            return m_Found;
        }

        const string& GetYear( ) const
        {
            return m_Year;
        }

        const string& GetMonth( ) const
        {
            return m_Month;
        }

        const string& GetDay( ) const
        {
            return m_Day;
        }

        const string& GetHours( ) const
        {
            return m_Hours;
        }

        const string& GetMinutes( ) const
        {
            return m_Minutes;
        }

        const string& GetSeconds( ) const
        {
            return m_Seconds;
        }

    protected:
        bool IsNumber( char Char )
        {
            if( '0' == Char || '1' == Char || '2' == Char || '3' == Char || '4' == Char ||
                '5' == Char || '6' == Char || '7' == Char || '8' == Char || '9' == Char )
            {
                return true;
            }

            return false;
        }

        string GetNumberString( string Text, string& Number )
        {
            int number_count = 0;
            for( ;; )
            {
                if( !IsNumber( Text[number_count] ) )
                {
                    break;
                }
                number_count++;
            }

            Number = Text.substr( 0, number_count );
            return Text.substr( number_count );
        }

        string DropWhitespace( string& Text )
        {
            try
            {
                return Text.substr( Text.find_first_not_of(' ') );
            }
            catch(...)
            {
                return Text;
            }

            return Text;
        }

    private:
        bool    m_Found;
        string  m_Output;
        string  m_Year;
        string  m_Month;
        string  m_Day;
        string  m_Hours;
        string  m_Minutes;
        string  m_Seconds;
};

class SnmpHostParser
{
    public:
        SnmpHostParser( ):
        m_Found( false )
        {

        }

        bool Parse( string Input )
        {
            m_Output = Input;
            size_t start_pos = Input.find_first_of( '[' );
            size_t end_pos = Input.find_last_of( ']' );
            if( string::npos == start_pos ||  string::npos == end_pos )
            {
                return false;
            }

            string hostBlock = Input.substr( start_pos +1, (end_pos-start_pos)-1  );

            start_pos = hostBlock.find_first_of( '[' );
            end_pos = hostBlock.find_first_of( ']' );
            if( string::npos == start_pos ||  string::npos == end_pos )
            {
                return false;
            }

            m_Host = hostBlock.substr( start_pos +1, (end_pos-start_pos)-1  );

            m_Found = true;
            return true;
        }

        const string& GetHost( ) const
        {
            return m_Host;
        }

    private:
        bool    m_Found;
        string  m_Output;
        string  m_Host;
};

ParserSnmp::ParserSnmp( )
{

}

ParserSnmp::~ParserSnmp( )
{

}

string ParserSnmp::Time2String( time_t time )
{
    char buffer[100];
    struct tm * timeinfo = localtime (&time);
    strftime( buffer, 100, "%F %T", timeinfo  );
    return string( buffer );
};

string ParserSnmp::GetTimeZone( )
{
    time_t Time = time( 0 );
    struct tm * timeinfo = localtime (&Time);
    return timeinfo->tm_zone;
}

int ParserSnmp::GetInteger( string String )
{
    stringstream ss;
    ss << String;
    int integer;
    ss >> integer;
    return integer;
}

string ParserSnmp::CreateTimestamp( int Year, int Month, int Day, int Hours, int Minutes, int Seconds )
{
    struct tm  timeinfo;
    memset( &timeinfo, 0, sizeof( struct tm ) );

    timeinfo.tm_hour  = Hours;
    timeinfo.tm_min   = Minutes;
    timeinfo.tm_sec   = Seconds;
    timeinfo.tm_year  = Year - 1900;
    timeinfo.tm_mon   = Month;
    timeinfo.tm_mday  = Day;
    timeinfo.tm_isdst = -1;

    return Time2String( mktime( &timeinfo ) ) + " " + GetTimeZone( );
}

string ParserSnmp::GetTimestamp( SnmpTimestampParser& TimestampParser )
{
    int Year    = GetInteger( TimestampParser.GetYear( ) );
    int Month   = GetInteger( TimestampParser.GetMonth( ) );
    int Day     = GetInteger( TimestampParser.GetDay( ) );
    int Hours   = GetInteger( TimestampParser.GetHours( ) );
    int Minutes = GetInteger( TimestampParser.GetMinutes( ) );
    int Seconds = GetInteger( TimestampParser.GetSeconds( ) );

    return CreateTimestamp( Year, Month, Day, Hours, Minutes, Seconds );
}

bool ParserSnmp::Parse( string Message, bool HasSourceIp, string SourceIP )
{
    SnmpTimestampParser timeParser;
    timeParser.Parse( Message );

    SnmpHostParser hostParser;
    if( timeParser.GetFound() )
    {
        hostParser.Parse( Message );

        if( m_Host.size() && m_TimeStamp.size() && m_AcumulatedMessage.size() )
        {
            Event event( EventProtocol::SNMP, "0", "", m_TimeStamp, m_Host, "", "", m_AcumulatedMessage, "", 0, 0 );
            m_Notifier.Notify( event );
        }

        m_AcumulatedMessage.clear( );
        m_Host = hostParser.GetHost( );
        m_TimeStamp = GetTimestamp( timeParser );
        m_AcumulatedMessage += timeParser.GetOutput( );
    }
    else
    {
        m_AcumulatedMessage += Message;
    }

    return true;
}

bool ParserSnmp::ProcessEndOfData( )
{
    if( m_Host.size() && m_TimeStamp.size() && m_AcumulatedMessage.size() )
    {
        Event event( EventProtocol::SNMP, "0", "", m_TimeStamp, m_Host, "", "", m_AcumulatedMessage, "", 0, 0 );
        m_Notifier.Notify( event );
    }

    return true;
}

void ParserSnmp::RegisterListener( ParserListener &Listener )
{
    m_Notifier.Register( Listener );
}

void ParserSnmp::UnregisterListener( ParserListener &Listener )
{
    m_Notifier.Unregister( Listener );
}
