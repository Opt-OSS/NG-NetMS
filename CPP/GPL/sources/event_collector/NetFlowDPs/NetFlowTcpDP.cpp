#include "NetFlowTcpDP.h"

#include <unistd.h>

#include <iostream>

NetFlowTcpDP::NetFlowTcpDP(int Port, string BindIPAddress): m_Port(Port), m_BindIPAddress(BindIPAddress), m_Interrupted(false)
{
}

NetFlowTcpDP::~NetFlowTcpDP()
{
}

void NetFlowTcpDP::OnConnected(int ConnectionId, std::string IpAddress)
{
	DataProviderListener::DataProviderEvent event(DataProviderListener::DataProviderEvent::Event::SOURCE_ATTACHED, string(), IpAddress);
	m_Notifier.Notify(event);
}

void NetFlowTcpDP::OnDisconnected(int ConnectionId, std::string IpAddress)
{
	DataProviderListener::DataProviderEvent event(DataProviderListener::DataProviderEvent::Event::SOURCE_DETTACHED, string(), IpAddress);
	m_Notifier.Notify(event);
}

void NetFlowTcpDP::OnReceiveData(int ConnectionId, const std::string& Data)
{
	DataProviderListener::DataProviderEvent event(DataProviderListener::DataProviderEvent::Event::DATA, Data);
	m_Notifier.Notify(event);
}

void NetFlowTcpDP::OnTransmitData(int ConnectionId)
{
}

bool NetFlowTcpDP::Run()
{
	if (!m_TcpServer.Initialize(m_Port, m_BindIPAddress))
	{
		return false;
	}

	m_TcpServer.RegisterHandler(*this);

	try
	{
		while (!m_Interrupted)
		{
			m_TcpServer.Process();
			usleep(1);
		}
	}
	catch (std::exception& e)
	{
		if (!m_Interrupted)
		{
			std::cerr << e.what() << std::endl;
		}
	}

	if (m_Interrupted)
	{
		return true;
	}

	return false;
}

bool NetFlowTcpDP::Stop()
{
	m_Interrupted = true;
	return true;
}

void NetFlowTcpDP::RegisterListener(DataProviderListener& Listener)
{
	m_Notifier.Register(Listener);
}

void NetFlowTcpDP::UnregisterListener(DataProviderListener& Listener)
{
	m_Notifier.Unregister(Listener);
}
