#pragma once

#include "IDataProvider.h"
#include <ctime>
#include <iostream>
#include <string>
#include <boost/asio.hpp>
#include <boost/array.hpp>
#include <memory>

using boost::asio::ip::udp;

class SyslogUdpDP: public IDataProvider
{
    public:
        SyslogUdpDP( int Port );
        virtual ~SyslogUdpDP( );
        bool Run( );
        bool Stop( );
        void RegisterListener( DataProviderListener &Listener );
        void UnregisterListener( DataProviderListener &Listener );

    private:
        void ReportMessage(  string& IpAddress,  string& Message );

    private:
        int     m_Port;
        bool    m_Interrupted;
        Notifier<DataProviderListener, DataProviderListener::DataProviderEvent&> m_Notifier;
        shared_ptr<udp::socket> m_Socket;
        map<string,string>      m_LastMessage;
};
