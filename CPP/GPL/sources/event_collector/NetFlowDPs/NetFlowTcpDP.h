#pragma once

#include "IDataProvider.h"
#include "TcpServer.h"

class NetFlowTcpDP: public IDataProvider, public ITcpServerHandlers
{
    public:
		NetFlowTcpDP( int Port, string BindIPAddress );
        virtual ~NetFlowTcpDP( );
        bool Run( );
        bool Stop( );
        void RegisterListener( DataProviderListener &Listener );
        void UnregisterListener( DataProviderListener &Listener );

    private:
    	virtual void OnConnected(int ConnectionId, std::string IpAddress);
    	virtual void OnDisconnected(int ConnectionId, std::string IpAddress);
    	virtual void OnReceiveData(int ConnectionId, const std::string& Data);
    	virtual void OnTransmitData(int ConnectionId);

    private:
        int 		m_Port;
        bool		m_Interrupted;
        string m_BindIPAddress;
        TcpServer	m_TcpServer;
        Notifier<DataProviderListener, DataProviderListener::DataProviderEvent&> m_Notifier;
};
