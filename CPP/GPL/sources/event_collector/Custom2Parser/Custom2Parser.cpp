#include "Custom2Parser.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstring>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

static string Time2String(time_t time)
{
	char buffer[100];
	struct tm* timeinfo = localtime(&time);
	strftime(buffer, 100, "%F %T", timeinfo);
	return string(buffer);
};

static string GetTimeZone()
{
	time_t Time = time(0);
	struct tm* timeinfo = localtime(&Time);
	return timeinfo->tm_zone;
}

static string GetTimestamp()
{
	using namespace std::chrono;

	system_clock::time_point now = system_clock::now();
	system_clock::duration tp = now.time_since_epoch();
	tp -= duration_cast<seconds>(tp);

	int millseconds = static_cast<unsigned>(tp / milliseconds(1));
	return Time2String(time(0)) + "." + to_string(millseconds) + " " + GetTimeZone();
}

static string GetHostName()
{
	char hostName[256];
	gethostname(hostName, sizeof hostName);
	return hostName;
}

class TokenParser
{
public:
	TokenParser(): m_Found(false) {}

	string& GetOutput() { return m_Output; }

	bool GetFound() { return m_Found; }

protected:
	void GetNumberString(string& Text, string& Number)
	{
		int cnt = 0;
		for (;;)
		{
			if (!isdigit(Text[cnt]))
			{
				break;
			}
			cnt++;
		}

		Number = Text.substr(0, cnt);
		Text.erase(0, cnt);
	}

	void GetString(string& Text, string& String)
	{
		size_t pos = Text.find(' ');
		if (string::npos == pos)
		{
			String = Text;
			Text.clear();
		}

		String = Text.substr(0, pos);
		Text.erase(0, pos + 1);
	}

	void DropWhitespace(string& Text)
	{
		std::size_t pos = Text.find_first_not_of(' ');
		if (pos == std::string::npos)
		{
			Text.clear();
		}

		Text.erase(0, pos);
	}

protected:
	string m_Output;
	bool m_Found;
	static vector<string> m_Months;
};

class Custom2FacilityCodeParser : public TokenParser
{
public:
	Custom2FacilityCodeParser() {}

	bool Parse(string Input)
	{
		m_Found = false;

		string host;
		string httpVersion;
		string ip1;
		string userAgent;
		string httpRequiestType;
		string uri;
		string unknown1;
		string unknown2;
		string ip2;
		string httpStatus;

		GetString(Input, host);
		GetString(Input, httpVersion);
		GetString(Input, ip1);
		GetString(Input, userAgent);
		GetString(Input, httpRequiestType);
		GetString(Input, uri);
		GetString(Input, unknown1);
		GetString(Input, unknown2);
		GetString(Input, ip2);
		GetString(Input, httpStatus);

		m_Facility = uri;
		m_Code = httpStatus;

		m_Output = Input;
		m_Found = true;
		return true;
	}

	string GetFacility() { return m_Facility; }

	string GetCode() { return m_Code; }

private:
	string m_Facility;
	string m_Code;
};

class Custom2TimestampParser : public TokenParser
{
public:
	Custom2TimestampParser() {}

	bool Parse(string Input)
	{
		m_Found = false;

		for (int i = 0; i < 14; ++i)
		{
			string ignore;
			GetString(Input, ignore);
		}

		string msecs_since_epoch;
		GetNumberString(Input, msecs_since_epoch);

		stringstream ss(msecs_since_epoch);
		unsigned long long time_in_msecs;
		ss >> time_in_msecs;

		int msecs = (time_in_msecs % 1000ULL);
		time_t seconds = (time_in_msecs / 1000ULL);

		struct tm* timeinfo = localtime(&seconds);
		char buffer[100];
		strftime(buffer, 100, "%F %T", timeinfo);
		m_Timestamp = (string(buffer) + "." + to_string(msecs) + " " + GetTimeZone());

		m_Output = Input;
		m_Found = true;
		return true;
	}

	string GetTimestamp() { return m_Timestamp; }

private:
	string m_Timestamp;
};

Custom2Parser::Custom2Parser()
{
}

Custom2Parser::~Custom2Parser()
{
}

bool Custom2Parser::Parse(string Message, bool HasSourceIp, string SourceIP)
{
	string code;
	string facility;
	static Custom2FacilityCodeParser custom2FacilityCodeParser;
	if (custom2FacilityCodeParser.Parse(Message))
	{
		code = custom2FacilityCodeParser.GetCode();
		facility = custom2FacilityCodeParser.GetFacility();
	}

	string timespamp = GetTimestamp();
	static Custom2TimestampParser custom2TimestampParser;
	if (custom2TimestampParser.Parse(Message))
	{
		timespamp = custom2TimestampParser.GetTimestamp();
	}

	Event event(EventProtocol::CUSTOM2, "0", GetTimestamp(), timespamp, GetHostName(), facility, code, Message, "", 0, 0);
	m_Notifier.Notify(event);
	return true;
}

bool Custom2Parser::ProcessEndOfData()
{
	return true;
}

void Custom2Parser::SourceAttached(string IpAddress)
{
}

void Custom2Parser::SourceDetached(string IpAddress)
{
}

void Custom2Parser::RegisterListener(ParserListener& Listener)
{
	m_Notifier.Register(Listener);
}

void Custom2Parser::UnregisterListener(ParserListener& Listener)
{
	m_Notifier.Unregister(Listener);
}
