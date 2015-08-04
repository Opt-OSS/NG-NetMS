#include "EventType.h"

EventType::EventType( const string& Name, EventProtocol Protocol, const Operator* Condition, int Severity, const string& Source, bool Discard ):
m_Name( Name ),
m_Protocol( Protocol ),
m_Severity( Severity ),
m_Discard( Discard ),
m_Condition( Condition )
{
    m_ActionScript = Source;
}

EventType::~EventType()
{
    if( m_Condition )
    {
         delete m_Condition;
    }
}
