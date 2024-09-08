
#pragma once

#include "Event.h"
#include "IParser.h"

struct CANLogEntry {
    int index;
    std::string timestamp;
    int canID;
    std::vector<std::string> data;
};

class CANParser : public IParser
{
public:
	CANParser();
	~CANParser();

	bool Parse(std::string Message, bool HasSourceIp, std::string SourceIP) override;
	bool ProcessEndOfData() override;
	void SourceAttached(std::string IpAddress) override;
	void SourceDetached(std::string IpAddress) override;
	void RegisterListener(ParserListener &Listener) override;
	void UnregisterListener(ParserListener &Listener) override;

private:
	CANLogEntry ParseCANLogLine(const std::string& line);
	std::string GetCurrentTimestamp();

private:
	Notifier<ParserListener, Event> m_Notifier;
	CANLogEntry m_currentCANEntry;
};
