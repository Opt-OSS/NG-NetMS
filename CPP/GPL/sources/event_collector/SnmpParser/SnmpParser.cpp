#include "SnmpParser.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <cctype>
#include <chrono>
#include <iostream>
#include <sstream>
#include <vector>

#include "Event.h"

class SnmpTimestampParser
{
public:
	SnmpTimestampParser(): m_Found(false) {}

	virtual ~SnmpTimestampParser() {}

	bool Parse(string Input)
	{
		m_Output = Input;
		if (20 > Input.size())
		{
			return false;
		}
		if ('-' != Input[4] || '-' != Input[7] || ' ' != Input[10])
		{
			return false;
		}

		if (':' != Input[13] || ':' != Input[16])
		{
			return false;
		}
		vector<size_t> numberIdxs;
		numberIdxs.push_back(0);  // Year
		numberIdxs.push_back(1);
		numberIdxs.push_back(2);
		numberIdxs.push_back(3);

		numberIdxs.push_back(5);  // Month
		numberIdxs.push_back(6);

		numberIdxs.push_back(8);  // Day
		numberIdxs.push_back(9);

		numberIdxs.push_back(11);  // Hour
		numberIdxs.push_back(12);

		numberIdxs.push_back(14);  // Minute
		numberIdxs.push_back(15);

		numberIdxs.push_back(17);  // Second
		numberIdxs.push_back(18);

		for (auto numIdx : numberIdxs)
		{
			if (!std::isdigit(Input[numIdx]))
			{
				return false;
			}
		}

		Input = GetNumberString(Input, m_Year);
		Input = Input.substr(1);
		Input = GetNumberString(Input, m_Month);
		Input = Input.substr(1);
		Input = GetNumberString(Input, m_Day);
		Input = Input.substr(1);

		Input = GetNumberString(Input, m_Hours);
		Input = Input.substr(1);
		Input = GetNumberString(Input, m_Minutes);
		Input = Input.substr(1);
		Input = GetNumberString(Input, m_Seconds);
		Input = Input.substr(1);

		m_Output = Input;
		m_Found = true;
		return true;
	}

	string GetOutput() { return m_Output; }

	bool GetFound() { return m_Found; }

	const string& GetYear() const { return m_Year; }

	const string& GetMonth() const { return m_Month; }

	const string& GetDay() const { return m_Day; }

	const string& GetHours() const { return m_Hours; }

	const string& GetMinutes() const { return m_Minutes; }

	const string& GetSeconds() const { return m_Seconds; }

protected:
	string GetNumberString(string Text, string& Number)
	{
		int number_count = 0;
		for (;;)
		{
			if (!std::isdigit(Text[number_count]))
			{
				break;
			}
			number_count++;
		}

		Number = Text.substr(0, number_count);
		return Text.substr(number_count);
	}

	string DropWhitespace(string& Text)
	{
		try
		{
			return Text.substr(Text.find_first_not_of(' '));
		}
		catch (...)
		{
			return Text;
		}

		return Text;
	}

private:
	bool m_Found;
	string m_Output;
	string m_Year;
	string m_Month;
	string m_Day;
	string m_Hours;
	string m_Minutes;
	string m_Seconds;
};

class SnmpHostParser
{
public:
	SnmpHostParser(): m_Found(false) {}

	bool Parse(string Input)
	{
		m_Output = Input;
		size_t start_pos = Input.find_first_of('[');
		size_t end_pos = Input.find_last_of(']');
		if (string::npos == start_pos || string::npos == end_pos)
		{
			return false;
		}

		string hostBlock = Input.substr(start_pos + 1, (end_pos - start_pos) - 1);

		start_pos = hostBlock.find_first_of('[');
		end_pos = hostBlock.find_first_of(']');
		if (string::npos == start_pos || string::npos == end_pos)
		{
			return false;
		}

		m_Host = hostBlock.substr(start_pos + 1, (end_pos - start_pos) - 1);

		m_Found = true;
		return true;
	}

	const string& GetHost() const { return m_Host; }

private:
	bool m_Found;
	string m_Output;
	string m_Host;
};

SnmpParser::SnmpParser()
{
}

SnmpParser::~SnmpParser()
{
}

string SnmpParser::Time2String(time_t time)
{
	char buffer[100];
	struct tm* timeinfo = localtime(&time);
	strftime(buffer, 100, "%F %T", timeinfo);
	return string(buffer);
};

string SnmpParser::GetTimeZone()
{
	time_t Time = time(0);
	struct tm* timeinfo = localtime(&Time);
	return timeinfo->tm_zone;
}

int SnmpParser::GetInteger(string String)
{
	stringstream ss;
	ss << String;
	int integer;
	ss >> integer;
	return integer;
}

string SnmpParser::CreateTimestamp(int Year, int Month, int Day, int Hours, int Minutes, int Seconds)
{
	struct tm timeinfo;
	memset(&timeinfo, 0, sizeof(struct tm));

	timeinfo.tm_hour = Hours;
	timeinfo.tm_min = Minutes;
	timeinfo.tm_sec = Seconds;
	timeinfo.tm_year = Year - 1900;
	timeinfo.tm_mon = Month;
	timeinfo.tm_mday = Day;
	timeinfo.tm_isdst = -1;

	return Time2String(mktime(&timeinfo)) + " " + GetTimeZone();
}

string SnmpParser::GetTimestamp(SnmpTimestampParser& TimestampParser)
{
	int Year = GetInteger(TimestampParser.GetYear());
	int Month = GetInteger(TimestampParser.GetMonth());
	int Day = GetInteger(TimestampParser.GetDay());
	int Hours = GetInteger(TimestampParser.GetHours());
	int Minutes = GetInteger(TimestampParser.GetMinutes());
	int Seconds = GetInteger(TimestampParser.GetSeconds());

	return CreateTimestamp(Year, Month, Day, Hours, Minutes, Seconds);
}

bool SnmpParser::Parse(string Message, bool HasSourceIp, string SourceIP)
{
	SnmpTimestampParser timeParser;
	timeParser.Parse(Message);

	SnmpHostParser hostParser;
	if (timeParser.GetFound())
	{
		hostParser.Parse(Message);

		if (m_Host.size() && m_TimeStamp.size() && m_AcumulatedMessage.size())
		{
			Event event(EventProtocol::SNMP, "0", GetTimestamp(), m_TimeStamp, m_Host, "", "", m_AcumulatedMessage, "", 0, 0);
			m_Notifier.Notify(event);
		}

		m_AcumulatedMessage.clear();
		m_Host = hostParser.GetHost();
		m_TimeStamp = GetTimestamp(timeParser);
		m_AcumulatedMessage += timeParser.GetOutput();
	}
	else
	{
		m_AcumulatedMessage += Message;
	}

	return true;
}

string SnmpParser::GetTimestamp()
{
	using namespace std::chrono;

	system_clock::time_point now = system_clock::now();
	system_clock::duration tp = now.time_since_epoch();
	tp -= duration_cast<seconds>(tp);

	int millseconds = static_cast<unsigned>(tp / milliseconds(1));
	return Time2String(time(0)) + "." + to_string(millseconds) + " " + GetTimeZone();
}

bool SnmpParser::ProcessEndOfData()
{
	if (m_Host.size() && m_TimeStamp.size() && m_AcumulatedMessage.size())
	{
		Event event(EventProtocol::SNMP, "0", "", m_TimeStamp, m_Host, "", "", m_AcumulatedMessage, "", 0, 0);
		m_Notifier.Notify(event);
	}

	return true;
}

void SnmpParser::SourceAttached(string IpAddress)
{
}

void SnmpParser::SourceDetached(string IpAddress)
{
}

void SnmpParser::RegisterListener(ParserListener& Listener)
{
	m_Notifier.Register(Listener);
}

void SnmpParser::UnregisterListener(ParserListener& Listener)
{
	m_Notifier.Unregister(Listener);
}
