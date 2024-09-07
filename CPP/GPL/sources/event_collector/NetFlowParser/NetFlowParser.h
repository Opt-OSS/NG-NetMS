#pragma once

#include <map>
#include <string>
#include <vector>

#include "IParser.h"
#include "NetFlowV5Parser.h"

class NetFlowParser : public IParser
{
public:
	NetFlowParser();
	bool Parse(string Message, bool HasSourceIp, string SourceIP);
	bool ProcessEndOfData();
	void SourceAttached(string IpAddress);
	void SourceDetached(string IpAddress);
	void RegisterListener(ParserListener &Listener);
	void UnregisterListener(ParserListener &Listener);

private:
	map<string, NetFlowV5Parser> m_Parsers;
	Notifier<ParserListener, Event> m_Notifier;
};
