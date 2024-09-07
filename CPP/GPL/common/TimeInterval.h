#pragma once

#include <string>
#include <sstream>

#include <iostream>

using namespace std;

class TimeInterval
{
    public:
        static const int SECONDS_IN_MINUTE = 60;
        static const int MINUTE_IN_HOUR    = 60;
        static const int HOURS_IN_DAY      = 24;

        static const int SECONDS_IN_HOUR = SECONDS_IN_MINUTE * MINUTE_IN_HOUR;
        static const int SECONDS_IN_DAY  = SECONDS_IN_HOUR   * HOURS_IN_DAY;

        enum class Units
        {
            Days,
            Hours,
            Minutes,
            Seconds,
            Unknown
        };

    public:
        TimeInterval( const TimeInterval& other ):
        m_Value( other.m_Value ),
        m_Units( other.m_Units )
        {

        }

        TimeInterval():
        m_Value( 0 ),
        m_Units( Units::Seconds )
        {

        }

        TimeInterval( int Value, Units Unit ):
        m_Value( Value ),
        m_Units( Unit )
        {

        }

        void SetValue( int Value )
        {
            m_Value = Value;
        }

        void SetUnit( Units Value )
        {
            m_Units = Value;
        }

        int GetValue( ) const
        {
            return m_Value;
        }

        Units GetUnit( ) const
        {
            return m_Units;
        }

        TimeInterval& operator= ( const TimeInterval& other )
        {
            m_Value = other.m_Value;
            m_Units = other.m_Units;
            return *this;
        }

        bool operator==( const TimeInterval& other ) const
        {
            return m_Value == other.m_Value && m_Units == other.m_Units;
        }

        bool operator!=( const TimeInterval& other ) const
        {
            return m_Value != other.m_Value || m_Units != other.m_Units;
        }

        bool operator<( const TimeInterval& other )
        {
            return GetValueInseconds( ) < other.GetValueInseconds( );
        }

        bool operator>( const TimeInterval& other )
        {
            return GetValueInseconds( ) > other.GetValueInseconds( );
        }

        string ToString() const
        {
            stringstream str;
            str << m_Value;
            str << UnitToString( m_Units );
            return str.str( );
        }

        bool FillFromString( const string Text )
        {
            string text;
            stringstream trimmer;
            trimmer << Text;
            trimmer >> text;
            trimmer.clear( );

            if( 2 > text.length( ) )
            {
                return false;
            }

            int letters = 0;
            for( char symbol : text )
            {
                if( isalpha( symbol ) )
                {
                    letters++;
                }
            }

            if( 1 <  letters )
            {
                return false;
            }

            Units unit = CharToUnit( text.back() );
            if( Units::Unknown == unit )
            {
                    return false;
            }
            m_Units = unit;

            text.erase( text.end()-1 );

            trimmer << text;
            trimmer >> m_Value;

            return true;
        }

        int GetValueInseconds( ) const
        {
            switch( m_Units )
            {
                case Units::Days:
                    return m_Value * SECONDS_IN_DAY;
                case Units::Hours:
                    return m_Value * SECONDS_IN_HOUR;
                case Units::Minutes:
                    return m_Value * SECONDS_IN_MINUTE;
                case Units::Seconds:
                    return m_Value;
                default:
                    return m_Value;
            }
        }

        int GetValueInUnit( TimeInterval::Units Unit )
        {
            switch( Unit )
            {
                case Units::Days:
                    return GetValueInseconds( ) / SECONDS_IN_DAY;
                case Units::Hours:
                    return GetValueInseconds( ) / SECONDS_IN_HOUR;
                case Units::Minutes:
                    return GetValueInseconds( ) / SECONDS_IN_MINUTE;
                case Units::Seconds:
                    return GetValueInseconds( );
                default:
                    return GetValueInseconds( );
            }
        }

    private:
        Units CharToUnit( const char Char )
        {
            switch( Char )
            {
                case 'd': return Units::Days;
                case 'h': return Units::Hours;
                case 'm': return Units::Minutes;
                case 's': return Units::Seconds;
                default: return  Units::Unknown;
            }
        }

        string UnitToString( const Units Unit ) const
        {
            switch( Unit )
            {
                case Units::Days:       return "d";
                case Units::Hours:      return "h";
                case Units::Minutes:    return "m";
                case Units::Seconds:    return "s";
                default:                return "s";
            }
        }

    private:
        int     m_Value;
        Units   m_Units;
};
