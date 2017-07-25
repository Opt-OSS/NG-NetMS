#pragma once

#include <string>

using namespace std;

enum class EventProtocol
{
    SYSLOG  = 0,
    SNMP    = 1,
    NETFLOW = 2,
    APACHE  = 3,
    CUSTOM1 = 4,
    CUSTOM2 = 5
};

static EventProtocol EventProtocolFromString( const string& String )
{
	if("syslog" == String)
	{
		return EventProtocol::SYSLOG;
	}
	else if( "snmp" == String )
	{
		return EventProtocol::SNMP;
	}
	else if( "netflow" == String )
	{
		return EventProtocol::NETFLOW;
	}
	else if( "apache" == String )
	{
		return EventProtocol::APACHE;
	}

	else if( "custom1" == String )
	{
		return EventProtocol::CUSTOM1;
	}
	else if( "custom2" == String )
	{
		return EventProtocol::CUSTOM2;
	}

	return EventProtocol::SYSLOG;
}
