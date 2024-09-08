#include "Event.h"
#include "Classifier.h"
#include "RulesFileParser.h"
#include <memory>
#include <iostream>

using namespace std;

Classifier::Classifier( bool Debug, std::shared_ptr<EventDecorator>& decorator):
m_Debug( Debug ),
m_decorator(decorator)
{

}

Classifier::~Classifier()
{

}

IClassifier::ResultCodes Classifier::Initialize( string RuleFile )
{
    switch( RulesFileParser::parse( RuleFile ) )
    {
        case RulesFileParser::ResultCodes::RESULT_CODE_OK:
            break;
        case RulesFileParser::ResultCodes::RESULT_CODE_CANT_OPEN_FILE:
            return IClassifier::ResultCodes::RESULT_CODE_CANT_OPEN_FILE;
        case RulesFileParser::ResultCodes::RESULT_CODE_PARSE_ERROR:
            return IClassifier::ResultCodes::RESULT_CODE_PARSE_ERROR;
    }

    if( m_Debug )
    {
        for( auto& eventType : RulesFileParser::GetEventTypeMap( ) )
        {
            shared_ptr<EventType> pEventType = eventType.second;

            string name            = pEventType->getName( );
            int severity           = pEventType->getSeverity( ) ;
            bool discard           = pEventType->discard( );
            string actionScript    = pEventType->getTriggerAction( );
            EventProtocol protocol = pEventType->getProtocol( );

            auto p2s = []( EventProtocol protocol ) -> string
            {
                if( EventProtocol::SYSLOG == protocol )
                {
                    return "SYSLOG";
                }
                else if( EventProtocol::SNMP == protocol )
                {
                    return "SNMP";
                }
                else if( EventProtocol::NETFLOW == protocol )
                {
                    return "NETFLOW";
                }
                else if( EventProtocol::CAN_BUS == protocol )
                {
                    return "CAN_BUS";
                }
                else
                {
                    return "";
                }
            };

            cout << p2s( protocol ) << " Rule " << name << " Severity = " << severity;
            if( discard )
            {
                cout << " Discard ";
            }

            const Operator* condition = pEventType->getCondition( );
            if( nullptr != condition )
            {
                cout << " Condition = " << condition->GetName( );
            }

            if( actionScript.length( ) )
            {
                cout << " ActionScript = " << actionScript;
            }

            cout << endl;
        }
    }

    return IClassifier::ResultCodes::RESULT_CODE_OK;
}

bool Classifier::Classify( Event& event )
{
     Event decoratedEvent = m_decorator->decoratedEvent(event); //if decoration is not needed return same event
     for( auto& eventType : RulesFileParser::GetEventTypeMap( ) )
     {
         shared_ptr<EventType> pEventType = eventType.second;
         if( pEventType->getProtocol() != decoratedEvent.getProtocol() )
         {
             continue;
         }
         
         bool process_event = false;
         if( pEventType->getCondition() )
         {
             process_event = pEventType->getCondition()->Calculate( &decoratedEvent );
         }
         else
         {
             process_event = true;
         }

         if( process_event )
         {
             if( eventType.second->discard( ) )
             {
                 ClassifierListener::ClassifierEvent c_event( decoratedEvent, eventType.second->getTriggerAction( ), true );
                 m_Notifier.Notify( c_event );
                 return true;
             }

             Event db_event( decoratedEvent.getProtocol(),
                 decoratedEvent.getPriority(),
                 decoratedEvent.getTs(),
                 decoratedEvent.getOrign_Ts(),
                 decoratedEvent.getOrigin(),
                 decoratedEvent.getFacility( ),
                 decoratedEvent.getCode( ),
                 decoratedEvent.getDescr(),
                 decoratedEvent.GetOriginalMessage( ),
                 decoratedEvent.getRouterId(),
                 eventType.second->getSeverity( ) );

             ClassifierListener::ClassifierEvent c_event( db_event, eventType.second->getTriggerAction( ), false );
             m_Notifier.Notify( c_event );

             return true;
         }
     }

     ClassifierListener::ClassifierEvent c_event( decoratedEvent, "", false );
     m_Notifier.Notify( c_event );
     return true;
}

void Classifier::RegisterListener( ClassifierListener &Listener )
{
     m_Notifier.Register( Listener );
}

void Classifier::UnregisterListener( ClassifierListener &Listener )
{
      m_Notifier.Unregister( Listener );
}
