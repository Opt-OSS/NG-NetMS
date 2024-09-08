#include "Database.h"
#include "Event.h"
#include "EventProtocol.h"

class EventDecorator {
public:

    EventDecorator(std::shared_ptr<Database> database) : m_Database(database) {}

    bool isNeedToDecorate(const Event& event) {
        if (event.getProtocol() == EventProtocol::CAN_BUS) {
            return true;
        }
        return false;
    }

    Event decoratedEvent(const Event& event) {
        if(!isNeedToDecorate(event)) // if decoration is not needed -> not even go to the database
        {
            return event;
        }
        switch (event.getProtocol()) {
        case EventProtocol::CAN_BUS:
        {
            std::string canDescription;
            std::string canName;

            if (m_Database->GetCANDescription(std::stoi(event.getCode()), canDescription, canName)) {
                Event decoratedEvent(   event.getProtocol(),
                                        event.getPriority(),
                                        event.getTs(),
                                        event.getOrign_Ts(),
                                        event.getOrigin(),
                                        event.getFacility( ),
                                        event.getCode( ),
                                        "[" + canName + "] " + canDescription,
                                        event.GetOriginalMessage( ),
                                        event.getRouterId(),
                                        event.getSeverity()
                );
                return decoratedEvent;
            }
            break;
        }
		case EventProtocol::SYSLOG:
		case EventProtocol::SNMP:
		case EventProtocol::NETFLOW:
		case EventProtocol::APACHE:
		case EventProtocol::CUSTOM1:
		case EventProtocol::CUSTOM2:
				break;		
        }
        return event;
    }

private:
    std::shared_ptr<Database> m_Database;
};
