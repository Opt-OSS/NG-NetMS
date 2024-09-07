#include "EventType.h"

EventType::EventType(const string& Name, EventProtocol Protocol, const Operator* Condition, int Severity, const string& Source, bool Discard):
	m_Name(Name), m_Protocol(Protocol), m_Severity(Severity), m_ActionScript(Source), m_Discard(Discard), m_Condition(Condition)
{
}

EventType::~EventType()
{
	delete m_Condition;
}
