#include "NetFlowParser.h"

#include <time.h>

#include <chrono>
#include <sstream>
#include <string>
#include <vector>

using namespace std;

static string Time2String(time_t time)
{
	char buffer[100];
	struct tm* timeinfo = localtime(&time);
	strftime(buffer, 100, "%F %T", timeinfo);
	return string(buffer);
}

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

static string IPAddressToString(uint32_t IpAddress)
{
	stringstream ss;
	ss << ((IpAddress >> 24) & 0xff) << ".";
	ss << ((IpAddress >> 16) & 0xff) << ".";
	ss << ((IpAddress >> 8) & 0xff) << ".";
	ss << (IpAddress & 0xff);
	return ss.str();
}

static string GenerateOriginalTimestamp(const NetFlowHeader_v5& Header)
{
	return Time2String(Header.GetUnixSecs()) + "." + to_string(Header.GetUnixNsecs() / 1000) + " " + GetTimeZone();
}

NetFlowParser::NetFlowParser()
{
}

bool NetFlowParser::Parse(string Message, bool HasSourceIp, string SourceIP)
{
	if (!HasSourceIp)
	{
		return false;
	}

	if (m_Parsers.end() == m_Parsers.find(SourceIP))
	{
		m_Parsers[SourceIP];
	}

	NetFlowV5Parser& parser = m_Parsers[SourceIP];

	parser.Parse(Message.c_str(), Message.size());
	if (parser.GetNetFlowPacketsCount())
	{
		vector<NetFlowPacket_v5> packets = parser.PeakNetFlowPackets();
		for (auto& p : packets)
		{
			string originalTimestamp = GenerateOriginalTimestamp(p.GetHeader());

			std::list<NetFlowRecord_v5> records = p.GetRecords();
			for (auto& r : records)
			{
				string priority = to_string(r.GetProt());
				string facility = to_string(r.GetDstPort());
				string code = to_string(r.GetSrcPort());
				string description = IPAddressToString(r.GetDstAddr()) + " " + IPAddressToString(r.GetSrcAddr()) + " " +
									 to_string(r.GetDPkts()) + " " + to_string(r.GetInput()) + " " + to_string(r.GetTOS()) +
									 " " + to_string(r.GetTcpFlags());
				string originalMessage;
				int severity = 0;

				Event event(
					EventProtocol::NETFLOW, priority, GetTimestamp(), originalTimestamp, SourceIP, facility, code, description, originalMessage, 0, severity
				);
				m_Notifier.Notify(event);
			}
		}
	}

	return true;
}

bool NetFlowParser::ProcessEndOfData()
{
	return true;
}

void NetFlowParser::SourceAttached(string IpAddress)
{
	m_Parsers[IpAddress];
}

void NetFlowParser::SourceDetached(string IpAddress)
{
	m_Parsers.erase(IpAddress);
}

void NetFlowParser::RegisterListener(ParserListener& Listener)
{
	m_Notifier.Register(Listener);
}

void NetFlowParser::UnregisterListener(ParserListener& Listener)
{
	m_Notifier.Unregister(Listener);
}
