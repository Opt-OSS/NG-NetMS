#pragma once

#include <boost/array.hpp>
#include <boost/asio.hpp>
#include <ctime>
#include <iostream>
#include <memory>
#include <string>

#include "IDataProvider.h"

using boost::asio::ip::udp;

class NetFlowUdpDP : public IDataProvider
{
public:
	NetFlowUdpDP(int Port, string BindIPAddress);
	virtual ~NetFlowUdpDP();
	bool Run();
	bool Stop();
	void RegisterListener(DataProviderListener &Listener);
	void UnregisterListener(DataProviderListener &Listener);

private:
	int m_Port;
	string m_BindIPAddress;
	bool m_Interrupted;
	Notifier<DataProviderListener, DataProviderListener::DataProviderEvent &> m_Notifier;
	shared_ptr<udp::socket> m_Socket;
};
