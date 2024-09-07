#pragma once

#include <string>

#include "Notifier.h"

using namespace std;

class DataProviderListener
{
public:
	class DataProviderEvent
	{
	public:
		enum class Event
		{
			DATA,  // Data received.
			// Data types:
			// 1. strings for text file
			// 2. PDUs for UDP
			// 3. Stream for TCP
			END_OF_DATA,  // File provider only.
			SOURCE_ATTACHED,  // TCP provider only. Sends on new client connected to the TCP server
			SOURCE_DETTACHED  // TCP provider only. Sends on client disconnected from the TCP server
		};

	public:
		DataProviderEvent(Event event, string Data = string(), string SourceIpAddress = string()):
			m_Event(event), m_String(Data), m_SourceIPAddress(SourceIpAddress)
		{
		}

		Event GetEvent() { return m_Event; }

		const string& GetData() const { return m_String; }

		bool GetHasSourceIP() { return !m_SourceIPAddress.empty(); }

		const string& GetSourceIPAddress() const { return m_SourceIPAddress; }

	private:
		Event m_Event;
		string m_String;
		string m_SourceIPAddress;
	};

public:
	virtual ~DataProviderListener() {}
	virtual void Notify(DataProviderEvent& data) = 0;
};

class IDataProvider
{
public:
	virtual ~IDataProvider() {}
	virtual bool Run() = 0;
	virtual bool Stop() = 0;
	virtual void RegisterListener(DataProviderListener& Listener) = 0;
	virtual void UnregisterListener(DataProviderListener& Listener) = 0;
};
