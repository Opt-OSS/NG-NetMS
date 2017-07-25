#pragma once
#include <string>
#include "EventProtocol.h"

using namespace std;

class Event
{
    public:
        Event( const Event& ) = default;
        Event( Event&& ) = default;

        Event( EventProtocol Protocol,
               const string& Priority,
               const string& TimeStamp,
               const string& OriginalTimestamp,
               const string& Origin,
               const string& Facility,
               const string& Code,
               const string& Description,
               const string& OriginalMessage,
               int           RouterId,
               int           Severity
            ):
            m_Protocol( Protocol ),
            m_Priority( Priority ),
            m_Timestamp( TimeStamp ),
            m_Origin( Origin  ),
            m_Facility( Facility ),
            m_Code( Code ),
            m_Description( Description ),
            m_OriginTimestamp( OriginalTimestamp ),
            m_OriginalMessage( OriginalMessage ),
            m_RouterId( RouterId ),
            m_Severity( Severity )
        {

        }

        EventProtocol getProtocol() const
        {
            return  m_Protocol;
        }

        const string& getPriority() const
        {
            return m_Priority;
        }

        void setTs(const string& Timestamp)
        {
        	m_Timestamp = Timestamp;
        }

        const string& getTs() const
        {
            return m_Timestamp;
        }

        const string& getOrign_Ts() const
        {
             return m_OriginTimestamp;
        }

        const string& getOrigin() const
        {
             return m_Origin;
        }

        const string& getFacility() const
        {
            return m_Facility;
        }

        const string& getCode() const
        {
            return m_Code;
        }

        const string& getDescr() const
        {
            return m_Description;
        }

        int getRouterId() const
        {
            return m_RouterId;
        }

        int getSeverity() const
        {
            return m_Severity;
        }

        const string& GetOriginalMessage( ) const
        {
            return m_OriginalMessage;
        }

  private:
        EventProtocol     m_Protocol;
        string            m_Priority;
        string            m_Timestamp;
        string            m_Origin;
        string            m_Facility;
        string            m_Code;
        string            m_Description;
        string            m_OriginTimestamp;
        string            m_OriginalMessage;
        int               m_RouterId;
        int               m_Severity;
};
