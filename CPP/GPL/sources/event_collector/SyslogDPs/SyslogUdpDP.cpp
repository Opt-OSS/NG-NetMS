#include "SyslogUdpDP.h"

#include <boost/bind.hpp>

SyslogUdpDP::SyslogUdpDP(int Port, string BindIPAddress): m_Port(Port), m_BindIPAddress(BindIPAddress), m_Interrupted(false)
{
}

SyslogUdpDP::~SyslogUdpDP()
{
}

void SyslogUdpDP::ReportMessage(string& IpAddress, string& Message)
{
	DataProviderListener::DataProviderEvent event(DataProviderListener::DataProviderEvent::Event::DATA, Message, IpAddress);
	m_Notifier.Notify(event);
}

bool SyslogUdpDP::Run()
{
	try
	{
		boost::asio::io_service io_service;

		// Construct a signal set registered for process termination.
		boost::asio::signal_set signals(io_service, SIGINT, SIGTERM);
		signals.async_wait(boost::bind(&boost::asio::io_service::stop, &io_service));
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

		recv_buf.data()[len] = '\0';
		string line(recv_buf.data());
		string ipAddress = remote_endpoint.address().to_string();

		// Process messages like this: <14>Nov 10 20:26:56 last message repeated 5 times
		const string firstToken = "last message repeated";
		const string lastToken = "times";
		size_t firstTokenPos = line.find(firstToken);
		size_t lastTokenPos = line.find(lastToken);

		bool repeatFound = false;
		size_t repetitionCount = 0;
		if (string::npos != firstTokenPos && string::npos != lastTokenPos)
		{
			string number = line.substr(firstTokenPos + firstToken.length() + 1);
			size_t spacePos = number.find_first_of(' ');
			if (string::npos != spacePos)
			{
				number = number.substr(0, spacePos);
				stringstream ss;
				ss << number;
				ss >> repetitionCount;

				repeatFound = true;
			}
		}

		if (repeatFound)
		{
			if (m_LastMessage.end() != m_LastMessage.find(ipAddress))
			{
				for (size_t i = 0; i < repetitionCount; ++i)
				{
					ReportMessage(ipAddress, m_LastMessage[ipAddress]);
				}
			}
		}
		else
		{
			// Save last event
			m_LastMessage[ipAddress] = line;
			ReportMessage(ipAddress, line);
		}
	}

	return true;
}

bool SyslogUdpDP::Stop()
{
	m_Interrupted = true;
	if (m_Socket.get())
	{
		m_Socket->shutdown(boost::asio::socket_base::shutdown_both);
	}

	return true;
}

void SyslogUdpDP::RegisterListener(DataProviderListener& Listener)
{
	m_Notifier.Register(Listener);
}

void SyslogUdpDP::UnregisterListener(DataProviderListener& Listener)
{
	m_Notifier.Unregister(Listener);
}
