#pragma once

#include <string>

#include "IParser.h"

using namespace std;

class ApacheParser : public IParser
{
public:
	ApacheParser();
	virtual ~ApacheParser();
	bool Parse(string Message, bool HasSourceIp, string SourceIP);
	bool ProcessEndOfData();
	void SourceAttached(string IpAddress);
	void SourceDetached(string IpAddress);
	void RegisterListener(ParserListener &Listener);
	void UnregisterListener(ParserListener &Listener);

private:
	Notifier<ParserListener, Event> m_Notifier;
};
