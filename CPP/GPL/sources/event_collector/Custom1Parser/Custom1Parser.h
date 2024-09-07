#pragma once

#include <string>

#include "IParser.h"

using namespace std;

class Custom1Parser : public IParser
{
public:
	Custom1Parser();
	virtual ~Custom1Parser();
	bool Parse(string Message, bool HasSourceIp, string SourceIP);
	bool ProcessEndOfData();
	void SourceAttached(string IpAddress);
	void SourceDetached(string IpAddress);
	void RegisterListener(ParserListener &Listener);
	void UnregisterListener(ParserListener &Listener);

private:
	Notifier<ParserListener, Event> m_Notifier;
};
