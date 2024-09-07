#pragma once

#include <map>
#include <string>
#include <vector>

class ITcpServerHandlers
{
public:
	virtual ~ITcpServerHandlers() {}
	virtual void OnConnected(int ConnectionId, std::string IpAddress) = 0;
	virtual void OnDisconnected(int ConnectionId, std::string IpAddress) = 0;
	virtual void OnReceiveData(int ConnectionId, const std::string& Data) = 0;
	virtual void OnTransmitData(int ConnectionId) = 0;
};

class TcpServer
{
	struct ClientData
	{
		std::string m_IpAddress;
		std::string m_RxBuffer;
		std::string m_TxBuffer;
	};

public:
	TcpServer();
	~TcpServer();
	bool Initialize(int Port, std::string BindIPAddress);
	std::pair<bool, std::string> GetIpAddress(int ConnectionId);
	bool SendData(int ConnectionId, const std::string& Data);
	void RegisterHandler(ITcpServerHandlers& Handlers);
	void Process();

private:
	bool RXData(int Socket);
	bool TXData(int Socket);
	void RemoveDisconnectedClients(std::vector<int>& Sockets);

private:
	int m_ListenSocket;
	bool m_Initialized;
	ITcpServerHandlers* m_Handlers;
	std::map<int, ClientData> m_IpAddresses;
};
