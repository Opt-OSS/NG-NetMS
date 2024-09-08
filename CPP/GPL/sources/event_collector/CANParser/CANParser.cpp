
#include "CANParser.h"
#include <string>

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

std::string CANParser::GetCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto now_time_t = std::chrono::system_clock::to_time_t(now);
    
    auto now_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
    
    std::tm* now_tm = std::localtime(&now_time_t);
    
    std::stringstream ss;
    ss << std::put_time(now_tm, "%H:%M:%S");
    ss << '.' << std::setfill('0') << std::setw(3) << now_ms.count();
    
    return ss.str();
}

bool CANParser::Parse(std::string Message, bool HasSourceIp, std::string SourceIP)
{
    m_currentCANEntry = ParseCANLogLine(Message);
    Event event(
        EventProtocol::CAN_BUS,                     //Protocol
        "0",                                        //Priority
        GetCurrentTimestamp(),                      //TimeStamp
        m_currentCANEntry.timestamp,                //OriginalTimestamp
        SourceIP,                                   //Origin
        "CAN",                                      //Facility
        std::to_string(m_currentCANEntry.canID),    //Code
        "Mystery CAN ID description",               //Description
        Message,                                    //OriginalMessage
        0,                                          //RouterId
        0                                           //Severity
    );
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
