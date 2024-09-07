#include "TcpServer.h"

#include <arpa/inet.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#include <vector>

using namespace std;

TcpServer::TcpServer(): m_ListenSocket(0), m_Initialized(false), m_Handlers(nullptr)
{
}

TcpServer::~TcpServer()
{
}

bool TcpServer::Initialize(int Port, string BindIPAddress)
{
	if (m_Initialized)
	{
		return true;
	}

	m_ListenSocket = socket(AF_INET, SOCK_STREAM, 0);
	if (m_ListenSocket < 0)
	{
		return false;
	}

	struct sockaddr_in sa_serv;
	memset(&sa_serv, '\0', sizeof(sa_serv));
	sa_serv.sin_family = AF_INET;
	//	sa_serv.sin_addr.s_addr = INADDR_ANY;
	sa_serv.sin_addr.s_addr = inet_addr(BindIPAddress.c_str());
	sa_serv.sin_port = htons(Port);

	int status = bind(m_ListenSocket, (struct sockaddr*)&sa_serv, sizeof(sa_serv));
	if (status < 0)
	{
		close(m_ListenSocket);
		return false;
	}

	status = listen(m_ListenSocket, 10);
	if (status < 0)
	{
		close(m_ListenSocket);
		return false;
	}

	// Set non-blocking
	if (fcntl(m_ListenSocket, F_SETFL, fcntl(m_ListenSocket, F_GETFL) | O_NONBLOCK) < 0)
	{
		close(m_ListenSocket);
		return false;
	}

	m_Initialized = true;

	return true;
}

std::pair<bool, std::string> TcpServer::GetIpAddress(int ConnectionId)
{
	auto it = m_IpAddresses.find(ConnectionId);
	if (it == m_IpAddresses.end())
	{
		return make_pair(false, "");
	}

	return make_pair(true, it->second.m_IpAddress);
}

bool TcpServer::SendData(int ConnectionId, const string& Data)
{
	auto it = m_IpAddresses.find(ConnectionId);
	if (it == m_IpAddresses.end())
	{
		return false;
	}

	it->second.m_TxBuffer.append(Data.c_str(), Data.size());
	return true;
}

void TcpServer::RegisterHandler(ITcpServerHandlers& Handlers)
{
	m_Handlers = &Handlers;
}

bool TcpServer::RXData(int Socket)
{
	fd_set read_sd;
	FD_ZERO(&read_sd);
	FD_SET(Socket, &read_sd);

	while (true)
	{
		fd_set rsd = read_sd;

		struct timeval timeout;
		timeout.tv_sec = 0;
		timeout.tv_usec = 0;

		int sel = select(Socket + 1, &rsd, 0, 0, &timeout);
		if (0 == sel)
		{
			break;
		}
		else if (sel > 0)
		{
			// client has performed some activity (sent data or disconnected?)
			char rx_buffer[4096] = {0};

			int bytes = recv(Socket, rx_buffer, sizeof(rx_buffer), 0);
			if (bytes > 0)
			{
				auto it = m_IpAddresses.find(Socket);
				if (m_IpAddresses.end() != it)
				{
					it->second.m_RxBuffer.append(rx_buffer, bytes);
				}
			}
			else if (bytes == 0)
			{
				return false;
			}
			else
			{
				// error receiving data from client. You may want to break from
				// while-loop here as well.
				return false;
			}
		}
		else if (sel < 0)
		{
			return false;  // grave error occurred.
		}
	}

	return true;
}

bool TcpServer::TXData(int Socket)
{
	auto it = m_IpAddresses.find(Socket);
	if (m_IpAddresses.end() == it)
	{
		return false;
	}

	bool error = false;
	while (!it->second.m_TxBuffer.empty())
	{
		int err = send(Socket, it->second.m_TxBuffer.c_str(), static_cast<int>(it->second.m_TxBuffer.size()), 0);
		if (err > 0)
		{
			it->second.m_TxBuffer.erase(0, err);
		}
		else if (0 == err)
		{
			break;
		}
		else
		{
			error = true;
			break;
		}
	}

	return !error;
}

void TcpServer::RemoveDisconnectedClients(vector<int>& Sockets)
{
	for (int s : Sockets)
	{
		// Notify client disconnect
		if (m_Handlers)
		{
			m_Handlers->OnDisconnected(s, m_IpAddresses[s].m_IpAddress);
		}

		m_IpAddresses.erase(s);
	}
}

void TcpServer::Process()
{
	if (!m_Initialized)
	{
		return;
	}

	// Check for new connections
	struct sockaddr_in sa_cli;
	socklen_t client_len = sizeof(sa_cli);
	int new_conn_fd = accept(m_ListenSocket, (struct sockaddr*)&sa_cli, &client_len);
	if (new_conn_fd > 0)
	{
		char ip_address[INET_ADDRSTRLEN];
		inet_ntop(AF_INET, &sa_cli.sin_addr, ip_address, sizeof ip_address);

		// Set non-blocking
		fcntl(new_conn_fd, F_SETFL, fcntl(new_conn_fd, F_GETFL) | O_NONBLOCK);

		m_IpAddresses[new_conn_fd].m_IpAddress = ip_address;

		// Notify that new client connected
		if (m_Handlers)
		{
			m_Handlers->OnConnected(new_conn_fd, ip_address);
		}
	}

	// Receive data from clients
	vector<int> disconnectedClients;
	for (auto& s : m_IpAddresses)
	{
		if (RXData(s.first))
		{
			if (s.second.m_RxBuffer.size())
			{
				// Notify received data
				if (m_Handlers)
				{
					m_Handlers->OnReceiveData(s.first, s.second.m_RxBuffer);
				}

				s.second.m_RxBuffer.clear();
			}
		}
		else
		{
			disconnectedClients.push_back(s.first);
		}
	}

	RemoveDisconnectedClients(disconnectedClients);

	// Transmit data to clients
	disconnectedClients.clear();
	for (auto& s : m_IpAddresses)
	{
		if (!s.second.m_TxBuffer.empty())
		{
			if (TXData(s.first))
			{
				// Notify transmitted data
				if (m_Handlers)
				{
					m_Handlers->OnTransmitData(s.first);
				}
			}
			else
			{
				disconnectedClients.push_back(s.first);
			}
		}
	}

	RemoveDisconnectedClients(disconnectedClients);
}
