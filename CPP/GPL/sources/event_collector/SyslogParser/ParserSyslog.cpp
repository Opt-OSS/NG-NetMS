#include "ParserSyslog.h"
#include <stdio.h>
#include <string>
#include <stdlib.h>
#include <time.h>
#include <algorithm>
#include <cstring>
#include <cctype>
#include <iostream>
#include <chrono>

class TokenParser
{
    public:
        TokenParser( ):
        m_Found( false )
        {

        }

        string& GetOutput( )
        {
            return m_Output;
        }

        bool GetFound( )
        {
            return m_Found;
        }

    protected:
        void GetNumberString( string &Text, string& Number )
        {
            int cnt = 0;
            for( ;; )
            {
                if( !isdigit( Text[cnt] ) )
                {
                    break;
                }
                cnt++;
            }

            Number = Text.substr( 0, cnt );
            Text.erase( 0, cnt );
        }

        void GetString( string &Text, string& String )
        {
            size_t pos = Text.find( ' ' );
            if( string::npos == pos )
            {
                String = Text;
                Text.clear( );
            }

            String = Text.substr( 0, pos );
            Text.erase( 0, pos + 1 );
        }

        void DropWhitespace( string& Text )
        {
             std::size_t pos = Text.find_first_not_of( ' ' );
             if( pos == std::string::npos )
             {
                 Text.clear( );
             }

             Text.erase( 0, pos );
        }

    protected:
        string          m_Output;
        bool            m_Found;
        static   vector<string>  m_Months;
};

vector<string> TokenParser::m_Months =
{
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
};

class PriorityParser : public TokenParser
{
    public:
        bool Parse( string& Input )
        {
            m_Found = false;

            size_t priority_start = Input.find( '<' );
            if( string::npos != priority_start && 0 == priority_start )
            {
                  size_t priority_end = Input.find( '>' );
                  size_t priority_lenght = priority_end - (priority_start + 1);
                  m_Priority = Input.substr( priority_start + 1, priority_lenght );
                  m_Output = Input.substr( priority_end + 1 );
                  m_Found = true;
                  return true;
            }

            return false;
        }

        string& GetPriority( )
        {
            return m_Priority;
        }

    private:
        string m_Priority;
};

class TimestampRFC3164Parser : public TokenParser
{
    public:
        TimestampRFC3164Parser( ):
        m_Month( 1 ),
        m_Day( 0 ),
        m_Hours( 0 ),
        m_Minutes( 0 ),
        m_Seconds( 0 )
        {

        }

        bool Parse( string& Input )
        {
            m_Month = 1;
            m_Found = false;

            for( string& month : m_Months )
            {
                if( 0 != Input.compare( 0, 3, month ) )
                {
                    m_Month++;
                    continue;
                }

                size_t dayStart = Input.find_first_not_of( ' ', 4 );
                size_t dayEnd = Input.find( ' ', dayStart + 1 );
                size_t hoursStart = Input.find_first_not_of( ' ', dayEnd +1 );
                size_t minutesStart = hoursStart + 3;
                size_t secondsStart = minutesStart + 3;
                size_t tailStart = secondsStart + 3;

                try
                {
                    m_Day     = stoi( Input.substr( dayStart, dayEnd - dayStart ) );
                    m_Hours   = stoi( Input.substr( hoursStart, 2 ) );
                    m_Minutes = stoi( Input.substr( minutesStart, 2 ) );
                    m_Seconds = stoi( Input.substr( secondsStart, 2 ) );
                }
                catch( ... )
                {
                    cerr << "TimestampRFC3164Parser::Parse Input = " << Input << endl;
                    return false;
                }

                m_Output  = Input.substr( tailStart );

                m_Found = true;
                return true;
            }

            return false;
        }

        int GetMonth( )
        {
            return m_Month;
        }

        int GetDay( )
        {
            return m_Day;
        }

        int GetHours( )
        {
            return m_Hours;
        }

        int GetMinutes( )
        {
            return m_Minutes;
        }

        int GetSeconds( )
        {
            return m_Seconds;
        }

    private:
        int m_Month;
        int m_Day;
        int m_Hours;
        int m_Minutes;
        int m_Seconds;
};

class CiscoDummyCounterParser : public TokenParser
{
    public:
        static constexpr size_t DUMMY_COUNTER_MAX_LENGTH = 20;
    public:
        CiscoDummyCounterParser( ):
        m_Counter( 0 )
        {

        }

        bool Parse( string& Input )
        {
            m_Found = false;
            m_Counter = 0;

            string dummyCounter = Input.substr( 0, DUMMY_COUNTER_MAX_LENGTH );
            size_t pos = dummyCounter.find( ':' );
            if( string::npos == pos )
            {
                return false;
            }

            dummyCounter.erase( pos );
            size_t startNumber = dummyCounter.find_first_not_of( ' ' );
            if( string::npos == startNumber )
            {
                return false;
            }

            dummyCounter = dummyCounter.substr( startNumber );
            for( auto sym : dummyCounter )
            {
                if( !isdigit( sym ) )
                {
                    return false;
                }
            }

            try
            {
                m_Counter = stoi( dummyCounter );
            }
            catch( ... )
            {
                return false;
            }

            m_Found = true;
            return true;
        }

        int GetCounter( )
        {
            return m_Counter;
        }

    private:
        int m_Counter;
};

class CiscoTimestampParser : public TokenParser
{
    public:
        CiscoTimestampParser( ):
        m_YearExist( false ),
        m_Year( 0 ),
        m_Month( 1 ),
        m_Day( 0 ),
        m_Hours( 0 ),
        m_Minutes( 0 ),
        m_Seconds( 0 )
        {

        }

        bool Parse( string Input )
        {
            m_YearExist = false;
            m_Month = 1;
            m_Found = false;

            // Remove first symbol
            if( ':' != Input[0] && '*' != Input[0] )
            {
                 return false;
            }

            Input.erase( 0, 1 );

            // Check for year
            if( isdigit( Input[0] ) &&
                isdigit( Input[1] ) &&
                isdigit( Input[2] ) &&
                isdigit( Input[3] ) )
            {
                string year;
                GetNumberString( Input, year );

                try
                {
                    m_Year =  stoi( year );
                    m_YearExist = true;
                }
                catch( ... )
                {
                    return false;
                }

                Input.erase( 0, 1 );
            }

            // Parse month, day, hours, minutes and seconds

            string mouth_str = Input.substr( 0,  4 );
            for( auto month : m_Months )
            {
                size_t date_start = mouth_str.find( month );
                if( string::npos != date_start )
                {
                    if( 0 != date_start )
                    {
                        return false;
                    }

                    string day, hours, minutes, seconds;
                    Input = Input.substr( date_start + month.length( ) + 1 );
                    DropWhitespace( Input );
                    GetNumberString( Input, day );
                    DropWhitespace( Input );
                    GetNumberString( Input, hours );
                    Input.erase( 0, 1 );
                    GetNumberString( Input, minutes );
                    Input.erase( 0, 1 );
                    GetNumberString( Input, seconds );
                    DropWhitespace( Input );

                    try
                    {
                        m_Day     = stoi( day );
                        m_Hours   = stoi( hours );
                        m_Minutes = stoi( minutes );
                        m_Seconds = stoi( seconds );
                    }
                    catch( ... )
                    {
                        return false;
                    }

                    break;
                }

                m_Month++;
            }

            if( 13 == m_Month )
            {
                return false;
            }

            m_Month %= 12;

            // Parse timezone
            for( auto timezone : m_CiscoTimezones )
            {
                size_t timezone_start = Input.find( timezone.first );
                if( string::npos != timezone_start )
                {
                    if( 0 != timezone_start )
                    {
                        return false;
                    }

                    GetString( Input, m_Timezone );
                    DropWhitespace( Input );
                }
            }

            if( '-' == Input[0] || '+' == Input[0] )
            {
                GetString( Input, m_Timeshift );
                DropWhitespace( Input );
            }

            m_Output = Input;
            m_Found = true;
            return true;
        }

        bool IsYearPresent( )
        {
            return m_YearExist;
        }

        int GetYear( )
        {
            return m_Year;
        }

        int GetMonth( )
        {
            return m_Month;
        }

        int GetDay( )
        {
            return m_Day;
        }

        int GetHours( )
        {
            return m_Hours;
        }

        int GetMinutes( )
        {
            return m_Minutes;
        }

        int GetSeconds( )
        {
            return m_Seconds;
        }

        string& GetTimezone( )
        {
            return m_Timezone;
        }

        string& GetTimeshift( )
        {
            return m_Timeshift;
        }

    private:
        static map<string, int> m_CiscoTimezones;
        bool             m_YearExist;
        int              m_Year;
        int              m_Month;
        int              m_Day;
        int              m_Hours;
        int              m_Minutes;
        int              m_Seconds;
        string           m_Timezone;
        string           m_Timeshift;
};

map<string, int> CiscoTimestampParser::m_CiscoTimezones =
{
    { "ACT", 95 },
    { "ADT", 30 },
    { "AET", 100 },
    { "AEST", 100 },
    { "AGT", -30 },
    { "AHST", -100 },
    { "ART", 20 },
    { "AST", -90 },
    { "AT", -20 },
    { "BET", -30 },
    { "BST",  10 },
    { "BT",  30 },
    { "CAT",  10 },
    { "CCT",  80 },
    { "CDT", -50 },
    { "CEST",  20 },
    { "CET",  10 },
    { "CNT", -35 },
    { "CST", -60 },
    { "CTT",  80 },
    { "EADT", -110 },
    { "EAST",  100 },
    { "EAT",  30 },
    { "ECT",  10 },
    { "EDT", -40 },
    { "EET",  20 },
    { "EST", -50 },
    { "FST", -20 },
    { "FWT",  10 },
    { "GMT",  0 },
    { "GST",  100 },
    { "HDT",  90 },
    { "HST", -100 },
    { "IDLE",  120 },
    { "IDLW", -120 },
    { "IET", -50 },
    { "IST",  55 },
    { "JST",  90 },
    { "MDT", -60 },
    { "MEST", -20 },
    { "MESZ", -20 },
    { "MET",  10 },
    { "MEWT",  10 },
    { "MIT", -110 },
    { "MST", -70 },
    { "MYT", 80 },
    { "NET",  40 },
    { "NST", 120 },
    { "NT", -110 },
    { "NZDT", 130 },
    { "NZST",  120 },
    { "NZT",  120 },
    { "PDT", -70 },
    { "PLT",  50 },
    { "PNT", -70 },
    { "PRT",  -40 },
    { "PST", -80 },
    { "SST", 110 },
    { "SWT",  10 },
    { "UTC",  0 },
    { "VST",  70 },
    { "WADT", -80 },
    { "WAST", 70 },
    { "WAT", -10 },
    { "YDT", -80 },
    { "YST", -90 },
    { "ZP4", 40 },
    { "ZP5", 50 },
    { "ZP6", 50 }
};

// Format 2017-05-19 00:05:47+00
class UnknownTimestampParser : public TokenParser
{
    public:
		UnknownTimestampParser( ):
        m_Year( 0 ),
        m_Month( 1 ),
        m_Day( 0 ),
        m_Hours( 0 ),
        m_Minutes( 0 ),
        m_Seconds( 0 ),
        m_Timezone( 0 )
        {

        }

        bool Parse( string Input )
        {
            m_Month = 1;
            m_Found = false;

            // Check for year
            if( isdigit( Input[0] ) &&
                isdigit( Input[1] ) &&
                isdigit( Input[2] ) &&
                isdigit( Input[3] ) )
            {
                string year;
                GetNumberString( Input, year );

                try
                {
                    m_Year =  stoi( year );
                }
                catch( ... )
                {
                    return false;
                }

                Input.erase( 0, 1 );
            }
            else
            {
				return false;
            }

            // Check for mount
            if( isdigit( Input[0] ) && isdigit( Input[1] ))
            {
				string month;
				GetNumberString( Input, month );

				try
				{
					m_Month =  stoi( month );
				}
				catch( ... )
				{
					return false;
				}

				Input.erase( 0, 1 );
            }
            else
            {
				return false;
            }

            // Check for day

            if( isdigit( Input[0] ) && isdigit( Input[1] ))
            {
				string day;
				GetNumberString( Input, day );

				try
				{
					m_Day =  stoi( day );
				}
				catch( ... )
				{
					return false;
				}

				Input.erase( 0, 1 );
            }
            else
            {
				return false;
            }

            // Check for hours
            if( isdigit( Input[0] ) && isdigit( Input[1] ))
            {
				string hours;
				GetNumberString( Input, hours );

				try
				{
					m_Hours =  stoi( hours );
				}
				catch( ... )
				{
					return false;
				}

				Input.erase( 0, 1 );
            }
            else
            {
				return false;
            }

            // Check for minutes
            if( isdigit( Input[0] ) && isdigit( Input[1] ))
            {
				string minutes;
				GetNumberString( Input, minutes );

				try
				{
					m_Minutes =  stoi( minutes );
				}
				catch( ... )
				{
					return false;
				}

				Input.erase( 0, 1 );
            }
            else
            {
				return false;
            }

            // Check for seconds
            if( isdigit( Input[0] ) && isdigit( Input[1] ))
            {
				string seconds;
				GetNumberString( Input, seconds );

				try
				{
					m_Seconds =  stoi( seconds );
				}
				catch( ... )
				{
					return false;
				}

				Input.erase( 0, 1 );
            }
            else
            {
				return false;
            }

            // Check for time zone
            if( isdigit( Input[0] ) && isdigit( Input[1] ))
            {
				string seconds;
				GetNumberString( Input, seconds );

				try
				{
					m_Timezone = stoi( seconds );
				}
				catch( ... )
				{
					return false;
				}

				Input.erase( 0, 1 );
            }
            else
            {
				return false;
            }

            m_Output = Input;
            m_Found = true;
            return true;
        }

        int GetYear( )
        {
            return m_Year;
        }

        int GetMonth( )
        {
            return m_Month;
        }

        int GetDay( )
        {
            return m_Day;
        }

        int GetHours( )
        {
            return m_Hours;
        }

        int GetMinutes( )
        {
            return m_Minutes;
        }

        int GetSeconds( )
        {
            return m_Seconds;
        }

        int GetTimezone( )
        {
            return m_Timezone;
        }

    private:
        int	m_Year;
        int	m_Month;
        int	m_Day;
        int	m_Hours;
        int	m_Minutes;
        int	m_Seconds;
        int	m_Timezone;
};

class CiscoFacilityBlockParser : public TokenParser
{
    public:
        bool Parse( string Input )
        {
            m_Found = false;

            m_Facility.clear( );
            m_SubFacility.clear( );
            m_Severity = 0;

            if( '%' != Input[0] ) // Remove first symbol
            {
                 return false;
            }

            string facilityBlock;

            Input.erase( 0, 1 );
            GetString( Input, facilityBlock );
            DropWhitespace( Input );

            int substringCount = count(  facilityBlock.begin(), facilityBlock.end(), '-' );
            if( 0 == substringCount )
            {
                return false;
            }

            replace( facilityBlock.begin(), facilityBlock.end(), '-', ' ' );

            GetString( facilityBlock, m_Facility );
            DropWhitespace( facilityBlock );

            string severity;
            if( 1 == substringCount )
            {
                GetString( facilityBlock, severity );
                DropWhitespace( facilityBlock );
            }
            else if( 2 == substringCount )
            {
                GetString( facilityBlock, m_SubFacility );
                DropWhitespace( facilityBlock );
                GetString( facilityBlock, severity );
            }

            try
            {
                m_Severity = stoi( severity );
            }
            catch( ... )
            {

            }

            m_Output = Input;
            m_Found = true;
            return true;
        }

        string& GetFacility( )
        {
            return m_Facility;
        }

        string& GetSubFacility( )
        {
            return m_SubFacility;
        }

        int GetSeverity( )
        {
            return m_Severity;
        }


    private:
        string m_Facility;
        string m_SubFacility;
        int    m_Severity;
};

class JunosFacilityParser : public TokenParser
{
    public:
        bool Parse( string& Input )
        {
            m_Found = false;
            m_Code.clear( );

            size_t firstColon  = Input.find( ':' );
            if( string::npos != firstColon )
            {
                if( string::npos != Input.rfind( ' ', firstColon ) )
                {
                    return false;
                }
            }

            size_t secondColon = ( string::npos == firstColon ) ? string::npos : Input.find( ':', firstColon + 1 );
            if( string::npos == firstColon || firstColon > m_JunosFacilityGroups.GetGroupNameMaxLenght( ) )
            {
                   return false;
            }

            string firstToken  = Input.substr( 0, firstColon );
            string secondToken;
            string thirdToken;

            if( string::npos != secondColon )
            {
                size_t secondTokenStart = Input.find_first_not_of( ' ', firstColon + 1 );
                size_t defis  = Input.rfind( '-', secondColon );

                if( string::npos == defis || defis < secondTokenStart )
                {
                    secondToken = Input.substr( secondTokenStart, secondColon - secondTokenStart );
                }
                else
                {
                    secondToken = Input.substr( defis + 1, secondColon - ( defis + 1) );
                    thirdToken  = Input.substr( secondTokenStart, defis - secondTokenStart );
                }
            }

            if( !CheckFacilityFormat( firstToken ) )
            {
                firstToken.clear( );
            }

            if( secondToken.size( ) > m_JunosFacilityGroups.GetGroupNameMaxLenght( ) || !CheckFacilityFormat( secondToken ) )
            {
                secondToken.clear( );
                thirdToken.clear( );
            }

            if( firstToken.empty( ) && secondToken.empty( ) )
            {
                return false;
            }

            if( secondToken.empty( ) ) // Lookup only by first token
            {
                for( auto &gpoup : m_JunosFacilityGroups.GetGroups( ) )
                {
                    string groupName = gpoup->GetGroupName( );
                    if( 0 != firstToken.compare( 0 , groupName.size(), groupName ) )
                    {
                        continue;
                    }

                    for( string& memberName : gpoup->GetFacilityNames( ) )
                    {
                        if( firstToken == memberName )
                        {
                            m_Facvility = firstToken;
                            m_Output = Input.substr( firstColon + 1 );
                            m_Found = true;
                            return true;
                        }
                    }
                }
            }
            else // Lookup by first token and by first if second token lookup failed
            {
                for( auto &gpoup : m_JunosFacilityGroups.GetGroups( ) )
                {
                    string groupName = gpoup->GetGroupName( );
                    if( 0 != secondToken.compare( 0 , groupName.size(), groupName ) )
                    {
                        continue;
                    }

                    for( string& memberName : gpoup->GetFacilityNames( ) )
                    {
                        if( secondToken == memberName )
                        {
                            m_Facvility = secondToken;
                            m_Code = thirdToken;
                            m_Output = Input.substr( secondColon + 1 );
                            m_Found = true;
                            return true;
                        }
                    }
                }

                for( auto &gpoup : m_JunosFacilityGroups.GetGroups( ) )
                {
                    string groupName = gpoup->GetGroupName( );
                    if( 0 != firstToken.compare( 0 , groupName.size(), groupName ) )
                    {
                        continue;
                    }

                    for( string& memberName : gpoup->GetFacilityNames( ) )
                    {
                        if( firstToken == memberName )
                        {
                            m_Facvility = firstToken;
                            m_Output = Input.substr( firstColon + 1 );
                            m_Found = true;
                            return true;
                        }
                    }
                }
            }

            return false;
        }

        string& GetFacility( )
        {
            return m_Facvility;
        }

        string& GetCode( )
        {
            return m_Code;
        }

    private:
        bool CheckFacilityFormat( string& Text )
        {
            for( auto symbol : Text )
            {
                if( '_' == symbol )
                {
                    continue;
                }

                if( isupper( symbol ) )
                {
                    continue;
                }

                return false;
            }

            return true;
        }

    private:
        static JunosFacilityGroups m_JunosFacilityGroups;
        string                     m_Facvility;
        string                     m_Code;

};

JunosFacilityGroups JunosFacilityParser::m_JunosFacilityGroups;

class HostnameParser : public TokenParser
{
    public:
        bool Parse( string& Input )
        {
            m_Found = false;
            m_Hostname.clear( );

            static CiscoDummyCounterParser ciscoDummyCounterParser;
            ciscoDummyCounterParser.Parse( Input );
            if( ciscoDummyCounterParser.GetFound( ) )
            {
                return false;
            }

            static CiscoTimestampParser ciscoTimestampParser;
            ciscoTimestampParser.Parse( Input );
            if( ciscoTimestampParser.GetFound( ) )
            {
                return false;
            }

            static CiscoFacilityBlockParser ciscoFacilityBlockParser;
            ciscoFacilityBlockParser.Parse( Input );
            if( ciscoFacilityBlockParser.GetFound( ) )
            {
                return false;
            }

            static JunosFacilityParser junosFacilityParser;
            junosFacilityParser.Parse( Input );
            if( junosFacilityParser.GetFound( ) )
            {
                return false;
            }

            //TODO: Add other parsers check

            size_t pos = Input.find( ' ' );
            if( string::npos == pos  )
            {
                return false;
            }

            m_Hostname = Input.substr( 0, pos );
            size_t tail = Input.find_first_not_of( ' ',  pos );
            if( string::npos == tail )
            {
                m_Output.clear( );
            }
            else
            {
                m_Output =  Input.substr( pos + 1 );
            }

            m_Found = true;
            return true;
        }

        string GetHostname( )
        {
            return m_Hostname;
        }

    private:
        string m_Hostname;
};

class ProcessPidParser : public TokenParser
{
    public:
        bool Parse( string Input )
        {
            m_Found = false;

            size_t position = Input.find( ' ' );
            if( string::npos == position )
            {
                return false;
            }

            string processPid = Input.substr( 0, position );

            bool kernel = processPid == "kernel:";

            if( (string::npos == processPid.find( '[' ) ||
                 string::npos == processPid.find( ']' )) &&
                 !kernel )
            {
                return false;
            }

            Input = Input.substr( position + 1 );

            // support for case => kernel: [timestamp]
            if( kernel )
            {
                DropWhitespace( Input );
                size_t startPosition  = Input.find( '[' );
                size_t finishPosition = Input.find( ']' );

                string secondPart;
                if( string::npos != startPosition && string::npos != finishPosition )
                {
                    secondPart = Input.substr( startPosition + 1, finishPosition  );
                    DropWhitespace( secondPart );
                    secondPart = "["  + secondPart;
                }

                if( secondPart.size() &&
                    string::npos == processPid.find( '[' ) &&
                    string::npos == processPid.find( ']' ) )
                {
                    processPid += " " + secondPart;
                    Input =  Input.substr( finishPosition  + 1 );
                }
            }

            replace( processPid.begin(), processPid.end(), '[', ' ' );
            replace( processPid.begin(), processPid.end(), ']', ' ' );
            replace( processPid.begin(), processPid.end(), ':', ' ' );

            GetString( processPid, m_Process );

            string sysCmdPrefix = "/usr/sbin/";
            if( 0 == m_Process.compare ( 0, sysCmdPrefix.size( ), sysCmdPrefix ) )
            {
                m_Process.erase( 0, sysCmdPrefix.size( ) );
            }

            DropWhitespace( processPid );
            GetString( processPid, m_Pid );

            DropWhitespace( Input );
            m_Output = Input;
            m_Found = true;
            return true;
        }

        string& GetProcess( )
        {
            return m_Process;
        }

        string& GetPid( )
        {
            return m_Pid;
        }

    private:
       string m_Process;
       string m_Pid;
};

class JunosStructuredPriorityParser : public TokenParser
{
    public:
        bool Parse( string& Input )
        {
            m_Found = false;

            static PriorityParser parser;
            parser.Parse( Input );
            if( !parser.GetFound( ) )
            {
                return false;
            }

            m_Priorioty = parser.GetPriority( );
            string tmp =  parser.GetOutput( );
            GetNumberString( tmp, m_Code );

            if( m_Code.empty( ) )
            {
                return false;
            }

            DropWhitespace( tmp );
            m_Output = tmp;
            m_Found = true;
            return true;
        }

        string& GetPriority( )
        {
            return m_Priorioty;
        }

        string& GetCode( )
        {
            return m_Code;
        }

    private:
        string m_Priorioty;
        string m_Code;      // I did not find any information about this field
};

class JunosStructuredTimestampParser : public TokenParser
{
    public:
        JunosStructuredTimestampParser( ):
        m_Year( 0 ),
        m_Month( 0 ),
        m_Day( 0 ),
        m_Hours( 0 ),
        m_Minutes( 0 ),
        m_Seconds( 0 )
        {

        }

        bool Parse( string Input )
        {
            m_Found = false;

            string timestamp;
            GetString( Input, timestamp );
            if( string::npos == timestamp.find( 'T' ) )
            {
               return false;
            }

            DropWhitespace( Input );
            replace( timestamp.begin(), timestamp.end(), 'T', ' ' );

            string dateStr;
            GetString( timestamp, dateStr );
            DropWhitespace( timestamp );

            if( string::npos == timestamp.find( '.' ) )
            {
                return false;
            }

            replace( timestamp.begin(), timestamp.end(), '.', ' ' );

            string timeStr;
            GetString( timestamp, timeStr );
            DropWhitespace( timestamp );
            m_TimeShift = timestamp;

            GetNumberString( m_TimeShift, m_Milliseconds );

            if( !ParseDate( dateStr ) )
            {
                return false;
            }

            if( !ParseTime( timeStr ) )
            {
                return false;
            }

            m_Output = Input;
            m_Found = true;
            return true;
        }

        bool ParseDate( string& Date )
        {
            string year, month, day;
            replace( Date.begin(), Date.end(), '-', ' ' );
            GetString( Date, year );
            DropWhitespace( Date );
            GetString( Date, month );
            DropWhitespace( Date );
            day = Date;

            try
            {
                m_Year  = stoi( year );
                m_Month = stoi( month );
                m_Day   = stoi( day );
            }
            catch( ... )
            {
                return false;
            }

            return true;
        }

        bool ParseTime( string& Time )
        {
            string hours, minutes, seconds;
            GetNumberString( Time, hours );
            Time.erase( 0, 1 );
            GetNumberString( Time, minutes );
            Time.erase( 0, 1 );
            GetNumberString( Time, seconds );

            try
            {
                m_Hours   = stoi( hours );
                m_Minutes = stoi( minutes );
                m_Seconds = stoi( seconds );
            }
            catch( ... )
            {
                return false;
            }

            return true;
        }

        int GetYear( )
        {
            return m_Year;
        }

        int GetMonth( )
        {
            return m_Month;
        }

        int GetDay( )
        {
            return m_Day;
        }

        int GetHours( )
        {
            return m_Hours;
        }

        int GetMinutes( )
        {
            return m_Minutes;
        }

        int GetSeconds( )
        {
            return m_Seconds;
        }

        string& GetMilliseconds( )
        {
            return m_Milliseconds;
        }

        string& GetTimeShift( )
        {
            return m_TimeShift;
        }

    private:
        int     m_Year;
        int     m_Month;
        int     m_Day;
        int     m_Hours;
        int     m_Minutes;
        int     m_Seconds;
        string  m_Milliseconds;
        string  m_TimeShift;
};

ParserSyslog::ParserSyslog( )
{

}

ParserSyslog::~ParserSyslog()
{

}

string ParserSyslog::Time2String( time_t time )
{
    char buffer[100];
    struct tm * timeinfo = localtime (&time);
    strftime( buffer, 100, "%F %T", timeinfo  );
    return string( buffer );
};

string ParserSyslog::GetTimestamp( )
{
	using namespace std::chrono;

	system_clock::time_point now = system_clock::now();
	system_clock::duration tp = now.time_since_epoch();
	tp -= duration_cast<seconds>(tp);

	int millseconds = static_cast<unsigned>(tp / milliseconds(1));
    return Time2String( time( 0 ) ) + "." + to_string(millseconds) + " " + GetTimeZone( );
}

int ParserSyslog::GetCurrentYear( )
{
    time_t Time = time( 0 );
    struct tm * timeinfo = localtime (&Time);
    return timeinfo->tm_year + 1900;
}

string ParserSyslog::GetTimeZone( )
{
    time_t Time = time( 0 );
    struct tm * timeinfo = localtime (&Time);
    return timeinfo->tm_zone;
}

string ParserSyslog::CreateTimestamp( int Year, int Month, int Day, int Hours, int Minutes, int Seconds )
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

string ParserSyslog::GetTimestamp( JunosStructuredTimestampParser& TimestampParser )
{
    if( !TimestampParser.GetFound() )
    {
        return GetTimestamp( );
    }

    int Year    = TimestampParser.GetYear( );
    int Month   = TimestampParser.GetMonth( )  - 1;
    int Day     = TimestampParser.GetDay( );
    int Hours   = TimestampParser.GetHours( );
    int Minutes = TimestampParser.GetMinutes( );
    int Seconds = TimestampParser.GetSeconds( );

    return CreateTimestamp( Year, Month, Day, Hours, Minutes, Seconds );
}

string ParserSyslog::GetTimestamp( TimestampRFC3164Parser& TimestampParser )
{
    if( !TimestampParser.GetFound() )
    {
        return GetTimestamp( );
    }

    int Year    = GetCurrentYear( );
    int Month   = TimestampParser.GetMonth( ) - 1;
    int Day     = TimestampParser.GetDay( );
    int Hours   = TimestampParser.GetHours( );
    int Minutes = TimestampParser.GetMinutes( );
    int Seconds = TimestampParser.GetSeconds( );

    return CreateTimestamp( Year, Month, Day, Hours, Minutes, Seconds );
}

string ParserSyslog::GetTimestamp( UnknownTimestampParser& TimestampParser )
{
    if( !TimestampParser.GetFound() )
    {
        return GetTimestamp( );
    }

    int Year    = GetCurrentYear( );
    int Month   = TimestampParser.GetMonth( ) - 1;
    int Day     = TimestampParser.GetDay( );
    int Hours   = TimestampParser.GetHours( );
    int Minutes = TimestampParser.GetMinutes( );
    int Seconds = TimestampParser.GetSeconds( );

    return CreateTimestamp( Year, Month, Day, Hours, Minutes, Seconds );
}

string ParserSyslog::GetTimestamp( CiscoTimestampParser& TimestampParser )
{
    if( !TimestampParser.GetFound() )
    {
        return GetTimestamp( );
    }

    int Year;
    if( TimestampParser.IsYearPresent( ) )
    {
        Year = TimestampParser.GetYear();
    }
    else
    {
        Year = GetCurrentYear( );
    }

    int Month   = TimestampParser.GetMonth( ) - 1;
    int Day     = TimestampParser.GetDay( );
    int Hours   = TimestampParser.GetHours( );
    int Minutes = TimestampParser.GetMinutes( );
    int Seconds = TimestampParser.GetSeconds( );

    return CreateTimestamp( Year, Month, Day, Hours, Minutes, Seconds );
}

class NetscreenDeviceIdParser : public TokenParser
{
    public:
        bool Parse( string& Input )
        {
            static string MARKER_STRING = "NetScreen device_id=";

            m_Found = false;

            size_t marker_start = Input.find( MARKER_STRING );
            if( string::npos == marker_start )
            {
                return false;
            }

            Input = Input.substr( marker_start + MARKER_STRING.length( ) );
            GetString( Input, m_DeviceId );

            DropWhitespace( Input );
            m_Output = Input;
            m_Found = true;
            return true;
        }

        string& GetDeviceId( )
        {
            return m_DeviceId;
        }

    private:
        string m_DeviceId;
};

class NetscreenFacilityParser : public TokenParser
{
    public:
        bool Parse( string Input )
        {
            m_Found = false;

            size_t stopMarker = Input.find( ':' );
            if( string::npos == stopMarker )
            {
                return false;
            }

            string facilityBLock = Input.substr( 0, stopMarker );

            size_t susbfacStart = facilityBLock.find_first_of( '(' );
            size_t susbfacEnd   = facilityBLock.find_first_of( ')' );
            if( susbfacEnd > susbfacStart )
            {
                m_Facility = facilityBLock.substr( susbfacStart + 1, susbfacEnd - susbfacStart - 1 );
                facilityBLock = facilityBLock.substr( 0, susbfacStart  );
            }

            size_t facilityMarker = facilityBLock.find_last_of( '-' );
            if( string::npos != facilityMarker )
            {
                m_SubFacility = facilityBLock.substr( facilityMarker + 1 );
            }

            if( m_Facility.empty( ) )
            {
                int subFacility = 0;
                try
                {
                    subFacility = stoi( m_SubFacility );
                }
                catch( ... )
                {

                }

                auto it = m_CodeToFacility.find( subFacility );
                if( it == m_CodeToFacility.end( ) )
                {
                    m_Facility = "system";
                }
                else
                {
                    m_Facility = it->second;
                }
            }

            m_Found = true;
            Input = Input.substr( stopMarker + 1 );
            DropWhitespace( Input );
            m_Output = Input;

            return true;
        }

        string& GetFacility( )
        {
            return m_Facility;
        }

        string& GetSubFacility( )
        {
            return m_SubFacility;
        }

    private:
        string                  m_SubFacility;
        string                  m_Facility;
        static map<int,string>  m_CodeToFacility;
};

map<int,string> NetscreenFacilityParser::m_CodeToFacility =
{
    { 257, "traffic" },
    { 528, "SSH" },
    { 536, "IKE" },
    { 518, "ADM" }
};

bool ParserSyslog::Parse( string Message, bool HasSourceIp, string SourceIP )
{
    // Save original message
    static string OriginalMessage;
    OriginalMessage = Message;

    static string hostName;
    bool parseHostName = !(SourceIP.size() && HasSourceIp);
    if( !parseHostName)
    {
        hostName =  SourceIP;
    }
    else
    {
        hostName.clear( );
    }

    bool netscreen = IsNetscreenFormat( Message );
    if( netscreen )
    {
        static PriorityParser priorityParser;
        priorityParser.Parse( Message );
        if( priorityParser.GetFound( ) )
        {
            Message = priorityParser.GetOutput( );
        }

        static TimestampRFC3164Parser timestampRFC3164Parser;
        timestampRFC3164Parser.Parse( Message );
        if( timestampRFC3164Parser.GetFound( ) )
        {
            Message = timestampRFC3164Parser.GetOutput( );
        }

        static NetscreenDeviceIdParser netscreenDeviceIdParser;
        netscreenDeviceIdParser.Parse( Message );
        if( netscreenDeviceIdParser.GetFound( ) )
        {
            Message = netscreenDeviceIdParser.GetOutput( );
        }

        static NetscreenFacilityParser netscreenFacilityParser;
        netscreenFacilityParser.Parse( Message );
        if( netscreenFacilityParser.GetFound( ) )
        {
            Message = netscreenFacilityParser.GetOutput( );
        }

        string priority;
        if( priorityParser.GetFound( ) )
        {
            priority = priorityParser.GetPriority( );
        }

        string facility;
        string eventCode;
        if( netscreenFacilityParser.GetFound( ) )
        {
            facility  = netscreenFacilityParser.GetFacility( );
            eventCode = netscreenFacilityParser.GetSubFacility( );
        }

        Event event( EventProtocol::SYSLOG, priority , GetTimestamp( ), GetTimestamp( timestampRFC3164Parser ), hostName, facility, eventCode, Message, OriginalMessage, 0, 0 );
        m_Notifier.Notify( event );

        return true;
    }
    else
    {
        bool junosFormat = false;
        static    JunosStructuredPriorityParser juniperStructPriorityParser;
        juniperStructPriorityParser.Parse( Message );
        if( juniperStructPriorityParser.GetFound( ) )
        {
            junosFormat = true;
            Message = juniperStructPriorityParser.GetOutput( );
        }

        if( junosFormat ) // We sure that we parse JunOS structured message
        {
            // Get Juniper time stamp
            static JunosStructuredTimestampParser timestampParser;

            timestampParser.Parse( Message );
            if( timestampParser.GetFound( ) )
            {
                Message = timestampParser.GetOutput( );
            }

            if( parseHostName )
            {
                // Get host name
                static HostnameParser hostnameParser;

                hostnameParser.Parse( Message );
                if( hostnameParser.GetFound() )
                {
                    Message = hostnameParser.GetOutput( );
                }

                hostName = hostnameParser.GetHostname( );
            }

            // Collect Event data
            static string eventPriority;
            if( juniperStructPriorityParser.GetFound( ) )
            {
                eventPriority = juniperStructPriorityParser.GetPriority( );
            }
            else
            {
                eventPriority = "0";
            }

            static string facility;
            static string eventCode;
            static JunosFacilityParser junosFacilityParser;

            junosFacilityParser.Parse( Message );
            if( junosFacilityParser.GetFound( ) )
            {
                Message = junosFacilityParser.GetOutput( );
                facility = junosFacilityParser.GetFacility( );
                eventCode =  junosFacilityParser.GetCode( );
            }
            else
            {
                facility = "";
            }

            Event event( EventProtocol::SYSLOG, eventPriority, GetTimestamp( ), GetTimestamp( timestampParser ), hostName, facility, eventCode, Message, OriginalMessage, 0, 0 );
            m_Notifier.Notify( event );
            return true;
        }
        else  // CISCO | Linux PC message
        {
            // Collect Event data
            static string eventOriginalTimestamp;

            static PriorityParser priorityParser;

            priorityParser.Parse( Message );
            if( priorityParser.GetFound( ) )
            {
                Message = priorityParser.GetOutput( );
            }

            static TimestampRFC3164Parser timestampRFC3164Parser;

            timestampRFC3164Parser.Parse( Message );
            if( timestampRFC3164Parser.GetFound( ) )
            {
                Message = timestampRFC3164Parser.GetOutput( );
            }

            static HostnameParser hostnameParser;
            hostnameParser.Parse( Message );
            if( hostnameParser.GetFound() )
            {
                Message = hostnameParser.GetOutput( );
            }

            if( parseHostName )
            {
                hostName = hostnameParser.GetHostname( );
            }

            // New Unknown time format parser
            static UnknownTimestampParser unknownTimestampParser;
            unknownTimestampParser.Parse( Message);
		    if( unknownTimestampParser.GetFound( ) )
			{
				Message = unknownTimestampParser.GetOutput( );
			}

            static CiscoDummyCounterParser ciscoDummyCounterParser;

            ciscoDummyCounterParser.Parse( Message );
            if( ciscoDummyCounterParser.GetFound( ) )
            {
                Message = ciscoDummyCounterParser.GetOutput( );
            }

            static CiscoTimestampParser ciscoTimestampParser;

            ciscoTimestampParser.Parse( Message );
            if( ciscoTimestampParser.GetFound( ) )
            {
                Message = ciscoTimestampParser.GetOutput( );
            }

            static CiscoFacilityBlockParser ciscoFacilityBlockParser;

            ciscoFacilityBlockParser.Parse( Message );
            if( ciscoFacilityBlockParser.GetFound( ) )
            {
                Message = ciscoFacilityBlockParser.GetOutput( );
            }

            static ProcessPidParser processPidParser;

            processPidParser.Parse( Message );
            if( processPidParser.GetFound( ) )
            {
                Message = processPidParser.GetOutput( );
            }

            // Fill event original times stamp
            if( ciscoTimestampParser.GetFound( ) ) // CISCO time stamp has higher priority
            {
                eventOriginalTimestamp = GetTimestamp( ciscoTimestampParser );
            }
            else if( timestampRFC3164Parser.GetFound( ) )
            {
                eventOriginalTimestamp = GetTimestamp( timestampRFC3164Parser );
            }
            else if( unknownTimestampParser.GetFound( ) )
            {
		        eventOriginalTimestamp = GetTimestamp( unknownTimestampParser );
            }
            else
            {
                eventOriginalTimestamp = GetTimestamp( );
            }

            static string eventPriority;
            if( priorityParser.GetFound( ) )
            {
                eventPriority = priorityParser.GetPriority( );
            }
            else
            {
                eventPriority = "0";
            }

            static string eventFacility;
            static string eventCode;
            int    eventSeverity = 0;
            if( ciscoFacilityBlockParser.GetFound( ) ) // CISCO facility block has higher priority
            {
                eventFacility = ciscoFacilityBlockParser.GetFacility( );
                eventCode = ciscoFacilityBlockParser.GetSubFacility( );
                eventSeverity = ciscoFacilityBlockParser.GetSeverity( );
            }
            else if( processPidParser.GetFound( ) )
            {
                eventFacility = processPidParser.GetProcess( );
                eventCode = processPidParser.GetPid( );
            }
            else
            {
                eventFacility.clear( );
                eventCode.clear( );
            }

            static JunosFacilityParser junosFacilityParser;
            junosFacilityParser.Parse( Message );
            if( junosFacilityParser.GetFound( ) )
            {
                Message = junosFacilityParser.GetOutput( );
                eventFacility = junosFacilityParser.GetFacility( );
                eventCode  = junosFacilityParser.GetCode( );
            }

            Event event( EventProtocol::SYSLOG, eventPriority, GetTimestamp( ), eventOriginalTimestamp, hostName, eventFacility, eventCode, Message, OriginalMessage, 0, eventSeverity );
            m_Notifier.Notify( event );
            return true;
        }
    }
}

bool ParserSyslog::IsNetscreenFormat( string& Text )
{
    return Text.find( "NetScreen device_id=" ) != string::npos;
}

bool ParserSyslog::ProcessEndOfData( )
{
    return true;
}

void ParserSyslog::SourceAttached( string IpAddress )
{

}

void ParserSyslog::SourceDetached( string IpAddress )
{

}

void ParserSyslog::RegisterListener( ParserListener &Listener )
{
    m_Notifier.Register( Listener );
}

void ParserSyslog::UnregisterListener( ParserListener &Listener )
{
    m_Notifier.Unregister( Listener );
}
