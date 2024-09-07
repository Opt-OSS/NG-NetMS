#include "NetFlowUdpDP.h"

#include <boost/bind.hpp>

NetFlowUdpDP::NetFlowUdpDP(int Port, string BindIPAddress): m_Port(Port), m_BindIPAddress(BindIPAddress), m_Interrupted(false)
{
}

NetFlowUdpDP::~NetFlowUdpDP()
{
}

bool NetFlowUdpDP::Run()
{
	try
	{
		boost::asio::io_service io_service;

		// Construct a signal set registered for process termination.
		boost::asio::signal_set signals(io_service, SIGINT, SIGTERM);
		signals.async_wait(boost::bind(&boost::asio::io_service::stop, &io_service));

		//        m_Socket = shared_ptr<udp::socket>( new udp::socket( io_service, udp::endpoint( udp::v4(), m_Port ) ) );
		m_Socket = shared_ptr<udp::socket>(
			new udp::socket(io_service, udp::endpoint(boost::asio::ip::address::from_string(m_BindIPAddress), m_Port))
		);
	}
	catch (...)
	{
		return false;
	}

	while (!m_Interrupted)
	{
		boost::array<char, 100 * 1024> recv_buf;
		udp::endpoint remote_endpoint;
		boost::system::error_code error;

		size_t len = m_Socket->receive_from(boost::asio::buffer(recv_buf), remote_endpoint, 0, error);
		if (error && error != boost::asio::error::message_size)
		{
			break;
		}

		string ipAddress = remote_endpoint.address().to_string();

		string data;
		data.append(recv_buf.data(), len);

		DataProviderListener::DataProviderEvent event(DataProviderListener::DataProviderEvent::Event::DATA, data, ipAddress);
		m_Notifier.Notify(event);
	}

	return true;
}

bool NetFlowUdpDP::Stop()
{
	m_Interrupted = true;
	if (m_Socket.get())
	{
		m_Socket->shutdown(boost::asio::socket_base::shutdown_both);
	}

	return true;
}

void NetFlowUdpDP::RegisterListener(DataProviderListener &Listener)
{
	m_Notifier.Register(Listener);
}

void NetFlowUdpDP::UnregisterListener(DataProviderListener &Listener)
{
	m_Notifier.Unregister(Listener);
}
