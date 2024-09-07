#pragma once

#include <string>
#include <map>

using namespace std;

enum class EventProtocol
{
    SYSLOG  = 0,
    SNMP    = 1,
    NETFLOW = 2,
    APACHE  = 3,
    CUSTOM1 = 4,
    CUSTOM2 = 5,
	CAN_BUS = 6
};

static map<EventProtocol, string>& GetProtocolToStringMapping( )
{
	static map<EventProtocol, string> protocols =
	{
			{ EventProtocol::SYSLOG, "syslog" },
			{ EventProtocol::SNMP, "snmp" },
			{ EventProtocol::NETFLOW, "netflow" },
			{ EventProtocol::APACHE, "apache" },
			{ EventProtocol::CUSTOM1, "custom1" },
			{ EventProtocol::CUSTOM2, "custom2" },
			{ EventProtocol::CAN_BUS, "can_bus" },
	};

	return protocols;
}

static EventProtocol EventProtocolFromString( const string& String )
{
	for( auto& e : GetProtocolToStringMapping())
	{
		if(e.second == String)
		{
			return e.first;
		}
	}

	return EventProtocol::SYSLOG;
}

static string EventProtocolToString( EventProtocol Protocol )
{
	map<EventProtocol, string> protocolMap = GetProtocolToStringMapping();
	auto it = protocolMap.find( Protocol );
	if(protocolMap.end() == it)
	{
		it = protocolMap.begin();
	}

	return it->second;
}
