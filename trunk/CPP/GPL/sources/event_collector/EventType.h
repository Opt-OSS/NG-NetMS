#pragma once

#include <cstdlib>
#include <cstring>
#include <string>
#include "Event.h"
#include "EventProtocol.h"

using namespace std;

class Operator
{
    public:
        Operator( const Operator* Left, const Operator* Right = nullptr ):
        m_Left( Left ),
        m_Right( Right )
        {

        }

        virtual ~Operator()
        {
            if( m_Right )
            {
                delete m_Right;
            }

            if( m_Left )
            {
                delete m_Left;
            }
        }

        virtual int Calculate( const Event* event ) const = 0;

        virtual string GetName( ) const
        {
            return "";
        }

    protected:
        const Operator* m_Left;
        const Operator* m_Right;
};

// EventType represents all events of the same type
class EventType
{
    public:
        EventType( const string& Name, EventProtocol Protocol= EventProtocol::SYSLOG, const Operator* Condition = nullptr,
                   int Severity = 10, const string& Source = "", bool Discard = false );

        ~EventType();

        const string& getName() const
        {
            return m_Name;
        }

        int getSeverity() const
        {
            return m_Severity;
        }

        const string& getTriggerAction() const
        {
            return m_ActionScript;
        }

        bool discard() const
        {
            return m_Discard;
        }

        EventProtocol getProtocol()
        {
            return m_Protocol;
        }

        const Operator* getCondition()
        {
            return m_Condition;
        }

    private:
        string          m_Name;
        EventProtocol   m_Protocol;
        int             m_Severity;
        string          m_ActionScript;
        bool            m_Discard;
        const Operator* m_Condition;

    private:
        EventType( const EventType& ) = delete;
        const EventType& operator =( const EventType& ) = delete;
};
