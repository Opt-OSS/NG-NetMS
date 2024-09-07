#pragma once

#include <boost/array.hpp>
#include <boost/asio.hpp>
#include <ctime>
#include <iostream>
#include <memory>
#include <string>

#include "IDataProvider.h"

using boost::asio::ip::tcp;

class SyslogTcpDP : public IDataProvider
{
public:
	SyslogTcpDP(int Port, string BindIpAddress);
	virtual ~SyslogTcpDP();
	bool Run();
	bool Stop();
	void RegisterListener(DataProviderListener &Listener);
	void UnregisterListener(DataProviderListener &Listener);

private:
	int m_Port;
	string m_BindIPAddress;
	bool m_Interrupted;
	Notifier<DataProviderListener, DataProviderListener::DataProviderEvent &> m_Notifier;
	shared_ptr<tcp::socket> m_Socket;
};
