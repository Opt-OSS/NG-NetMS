#include "ApacheParser.h"

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstring>
#include <iostream>
#include <string>
#include <vector>

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

// Format 2017-05-25 20:21:19:464912
class ApacheTimestampParser : public TokenParser
{
public:
	ApacheTimestampParser(): m_Year(0), m_Month(1), m_Day(0), m_Hours(0), m_Minutes(0), m_Seconds(0), m_USeconds(0) {}

	bool Parse(string Input)
	{
		m_Month = 1;
		m_Found = false;

		// Check for year
		if (isdigit(Input[0]) && isdigit(Input[1]) && isdigit(Input[2]) && isdigit(Input[3]))
		{
			string year;
			GetNumberString(Input, year);

			try
			{
				m_Year = stoi(year);
			}
			catch (...)
			{
				return false;
			}

			Input.erase(0, 1);
		}
		else
		{
			return false;
		}

		// Check for mount
		if (isdigit(Input[0]) && isdigit(Input[1]))
		{
			string month;
			GetNumberString(Input, month);

			try
			{
				m_Month = stoi(month);
			}
			catch (...)
			{
				return false;
			}

			Input.erase(0, 1);
		}
		else
		{
			return false;
		}

		// Check for day

		if (isdigit(Input[0]) && isdigit(Input[1]))
		{
			string day;
			GetNumberString(Input, day);

			try
			{
				m_Day = stoi(day);
			}
			catch (...)
			{
				return false;
			}

			Input.erase(0, 1);
		}
		else
		{
			return false;
		}

		// Check for hours
		if (isdigit(Input[0]) && isdigit(Input[1]))
		{
			string hours;
			GetNumberString(Input, hours);

			try
			{
				m_Hours = stoi(hours);
			}
			catch (...)
			{
				return false;
			}

			Input.erase(0, 1);
		}
		else
		{
			return false;
		}

		// Check for minutes
		if (isdigit(Input[0]) && isdigit(Input[1]))
		{
			string minutes;
			GetNumberString(Input, minutes);

			try
			{
				m_Minutes = stoi(minutes);
			}
			catch (...)
			{
				return false;
			}

			Input.erase(0, 1);
		}
		else
		{
			return false;
		}

		// Check for seconds
		if (isdigit(Input[0]) && isdigit(Input[1]))
		{
			string seconds;
			GetNumberString(Input, seconds);

			try
			{
				m_Seconds = stoi(seconds);
			}
			catch (...)
			{
				return false;
			}

			Input.erase(0, 1);
		}
		else
		{
			return false;
		}

		// Check for time useconds
		if (isdigit(Input[0]) && isdigit(Input[1]) && isdigit(Input[2]) && isdigit(Input[3]) && isdigit(Input[4]) && isdigit(Input[5]))
		{
			string seconds;
			GetNumberString(Input, seconds);

			try
			{
				m_USeconds = stoi(seconds);
			}
			catch (...)
			{
				return false;
			}

			Input.erase(0, 1);
		}
		else
		{
			return false;
		}

		m_Output = Input;
		m_Found = true;
		return true;
	}

	int GetYear() { return m_Year; }

	int GetMonth() { return m_Month; }

	int GetDay() { return m_Day; }

	int GetHours() { return m_Hours; }

	int GetMinutes() { return m_Minutes; }

	int GetSeconds() { return m_Seconds; }

	int GetUseconds() { return m_USeconds; }

private:
	int m_Year;
	int m_Month;
	int m_Day;
	int m_Hours;
	int m_Minutes;
	int m_Seconds;
	int m_USeconds;
};

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

static string CreateTimestamp(int Year, int Month, int Day, int Hours, int Minutes, int Seconds, int USeconds)
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

	return Time2String(mktime(&timeinfo)) + "." + to_string(USeconds) + " " + GetTimeZone();
}

static string GetTimestamp(ApacheTimestampParser& TimestampParser)
{
	if (!TimestampParser.GetFound())
	{
		return GetTimestamp();
	}

	int Year = TimestampParser.GetYear();
	int Month = TimestampParser.GetMonth() - 1;
	int Day = TimestampParser.GetDay();
	int Hours = TimestampParser.GetHours();
	int Minutes = TimestampParser.GetMinutes();
	int Seconds = TimestampParser.GetSeconds();
	int USeconds = TimestampParser.GetUseconds();

	return CreateTimestamp(Year, Month, Day, Hours, Minutes, Seconds, USeconds);
}

class ApacheCodeParser : public TokenParser
{
public:
	ApacheCodeParser() {}

	bool Parse(string Input)
	{
		m_Found = false;

		GetString(Input, m_Code);
		if (m_Code.size() != 1)
		{
			return false;
		}

		m_Output = Input;
		m_Found = true;
		return true;
	}

	string GetCode() { return m_Code; }

private:
	string m_Code;
};

class ApacheFacilityParser : public TokenParser
{
public:
	ApacheFacilityParser() {}

	bool Parse(string Input)
	{
		m_Found = false;

		size_t position = Input.find_first_of(":");
		if (string::npos == position)
		{
			return false;
		}

		m_Facility = Input.substr(0, position);
		DropWhitespace(m_Facility);

		Input = Input.substr(position + 2);
		m_Output = Input;
		m_Found = true;
		return true;
	}

	string GetFacility() { return m_Facility; }

private:
	string m_Facility;
};

static string GetHostName()
{
	char hostName[256];
	gethostname(hostName, sizeof hostName);
	return hostName;
}

ApacheParser::ApacheParser()
{
}

ApacheParser::~ApacheParser()
{
}

bool ApacheParser::Parse(string Message, bool HasSourceIp, string SourceIP)
{
	string OriginalMessage;

	OriginalMessage = Message;

	static ApacheTimestampParser apacheTimestampParser;

	string timespamp;
	//TODO add support for 23/Aug/2017:14:04:46 +0100 (Ubuntu default)
	if (apacheTimestampParser.Parse(Message))
	{
		timespamp = GetTimestamp(apacheTimestampParser);
		Message = apacheTimestampParser.GetOutput();
	}

	static ApacheCodeParser apacheCodeParser;

	string code;
	if (apacheCodeParser.Parse(Message))
	{
		code = apacheCodeParser.GetCode();
		Message = apacheCodeParser.GetOutput();
	}

	static ApacheFacilityParser apacheFacilityParser;

	string facility;
	if (apacheFacilityParser.Parse(Message))
	{
		facility = apacheFacilityParser.GetFacility();
		Message = apacheFacilityParser.GetOutput();
	}

	Event event(EventProtocol::APACHE, "0", GetTimestamp(), timespamp, GetHostName(), facility, code, Message, OriginalMessage, 0, 0);
	m_Notifier.Notify(event);
	return true;
}

bool ApacheParser::ProcessEndOfData()
{
	return true;
}

void ApacheParser::SourceAttached(string IpAddress)
{
}

void ApacheParser::SourceDetached(string IpAddress)
{
}

void ApacheParser::RegisterListener(ParserListener& Listener)
{
	m_Notifier.Register(Listener);
}

void ApacheParser::UnregisterListener(ParserListener& Listener)
{
	m_Notifier.Unregister(Listener);
}
