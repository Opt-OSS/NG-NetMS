#pragma once

#include <string>
#include "Notifier.h"

using namespace std;

class DataProviderListener
{
    public:
        class DataProviderEvent
        {
            public:
                enum class Event
                {
                    DATA,
                    END_OF_DATA
                };

            public:
              DataProviderEvent( Event event ):
              m_Event( event ),
              m_HasSourceIP( true )
              {

              }

              DataProviderEvent( Event event, string& Data ):
              m_Event( event ),
              m_String( Data ),
              m_HasSourceIP( true )
              {

              }

              DataProviderEvent( Event event, string& Data, string SourceIpAddress ):
              m_Event( event ),
              m_String( Data ),
              m_HasSourceIP( false ),
              m_SourceIPAddress( SourceIpAddress )
              {

              }

              Event GetEvent( )
              {
                  return m_Event;
              }

              const string& GetData( ) const
              {
                  return m_String;
              }

              bool GetHasSourceIP( )
              {
                  return m_HasSourceIP;
              }

              const string& GetSourceIPAddress( ) const
              {
                  return m_SourceIPAddress;
              }

            private:
              Event  m_Event;
              string m_String;
              bool   m_HasSourceIP;
              string m_SourceIPAddress;
        };

    public:
        virtual ~DataProviderListener() { }
        virtual void Notify( DataProviderEvent& data ) = 0;
};

class IDataProvider
{
    public:
        virtual ~IDataProvider( ){ }
        virtual bool Run( ) = 0;
        virtual bool Stop( ) = 0;
        virtual void RegisterListener( DataProviderListener &Listener ) = 0;
        virtual void UnregisterListener( DataProviderListener &Listener ) = 0;
};
