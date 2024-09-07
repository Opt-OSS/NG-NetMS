
#include "CANParser.h"

CANParser::CANParser() {}

CANParser::~CANParser() {}

CANLogEntry CANParser::ParseCANLogLine(const std::string& line) {
    CANLogEntry entry;
    std::istringstream stream(line);

    // Parse index, timestamp, CAN ID
    stream >> entry.index >> entry.timestamp >> entry.canID;

    // Parse the remaining data fields (variable number of bytes)
    std::string byte;
    while (stream >> byte) {
        entry.data.push_back(byte);
    }

    return entry;
}

bool CANParser::Parse(std::string Message, bool HasSourceIp, std::string SourceIP)
{
    // Placeholder: You will add CAN data parsing logic here
    std::cout << "Parsing CAN data: " << Message << std::endl;

    // For now, we'll simulate creating an Event object
    Event event(EventProtocol::CUSTOM1, "0", "0", "0", SourceIP, "CAN", "CODE", "CAN data description", Message, 0, 0);
    m_Notifier.Notify(event);

    return true;
}

bool CANParser::ProcessEndOfData()
{
    std::cout << "CAN parsing completed." << std::endl;
    return true;
}

void CANParser::SourceAttached(std::string IpAddress)
{
    std::cout << "CAN source attached: " << IpAddress << std::endl;
}

void CANParser::SourceDetached(std::string IpAddress)
{
    std::cout << "CAN source detached: " << IpAddress << std::endl;
}

void CANParser::RegisterListener( ParserListener &Listener )
{
    m_Notifier.Register( Listener );
}

void CANParser::UnregisterListener( ParserListener &Listener )
{
    m_Notifier.Unregister( Listener );
}
