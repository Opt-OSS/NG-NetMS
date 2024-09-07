#pragma once

#include <string>

#include "IParser.h"

using namespace std;

class SnmpTimestampParser;

class SnmpParser : public IParser
{
public:
	SnmpParser();
	virtual ~SnmpParser();
	bool Parse(string Message, bool HasSourceIp, string SourceIP);
	bool ProcessEndOfData();
	string GetTimestamp();
	void SourceAttached(string IpAddress);
	void SourceDetached(string IpAddress);
	void RegisterListener(ParserListener &Listener);
	void UnregisterListener(ParserListener &Listener);

private:
	string Time2String(time_t time);
	string GetTimestamp(SnmpTimestampParser &TimestampParser);
	string GetTimeZone();
	int GetInteger(string String);
	string CreateTimestamp(int Year, int Month, int Day, int Hours, int Minutes, int Seconds);

private:
	string m_Host;
	string m_TimeStamp;
	string m_AcumulatedMessage;
	Notifier<ParserListener, Event> m_Notifier;
};
