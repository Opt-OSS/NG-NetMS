#pragma once

#include "IDataProvider.h"
#include "TcpDataProvider.h"
#include <ctime>
#include <iostream>
#include <string>
#include <boost/asio.hpp>
#include <boost/array.hpp>
#include <memory>

using boost::asio::ip::tcp;

class TcpDataProvider: public IDataProvider
{
    public:
        TcpDataProvider( int Port );
        virtual ~TcpDataProvider( );
        bool Run( );
        bool Stop( );
        void RegisterListener( DataProviderListener &Listener );
        void UnregisterListener( DataProviderListener &Listener );

    private:
        int     m_Port;
        bool    m_Interrupted;
        Notifier<DataProviderListener, DataProviderListener::DataProviderEvent&> m_Notifier;
        shared_ptr<tcp::socket> m_Socket;
};
