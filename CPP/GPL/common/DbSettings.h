#pragma once

#include <string>

#include "ConfigFileReader.h"
#include "ConfigFileWriter.h"
#include "Configuration.h"
#include "Cryptography.h"

using namespace std;

static const TimeInterval MIN_DB_CONNECTION_TIMEOUT(1, TimeInterval::Units::Seconds);
static const TimeInterval MAX_DB_CONNECTION_TIMEOUT(1000, TimeInterval::Units::Seconds);

class DbSettings
{
public:
	DbSettings(): m_Port(0), m_Timeout(0) {}

	DbSettings(const DbSettings& Other):
		m_Host(Other.m_Host), m_Port(Other.m_Port), m_DbName(Other.m_DbName), m_DbUser(Other.m_DbUser),
		m_DbPassword(Other.m_DbPassword), m_Timeout(Other.m_Timeout)
	{
	}

	DbSettings(string Host, unsigned int Port, string DbName, string DbUser, string DbPassword, unsigned int Timeout):
		m_Host(Host), m_Port(Port), m_DbName(DbName), m_DbUser(DbUser), m_DbPassword(DbPassword), m_Timeout(Timeout)
	{
	}

	DbSettings& operator=(const DbSettings& Other)
	{
		m_Host = Other.m_Host;
		m_Port = Other.m_Port;
		m_DbName = Other.m_DbName;
		m_DbUser = Other.m_DbUser;
		m_DbPassword = Other.m_DbPassword;
		m_Timeout = Other.m_Timeout;
		return *this;
	}

	const string GetHost() const { return m_Host; }

	const unsigned int GetPort() const { return m_Port; }

	const string GetDbName() const { return m_DbName; }

	const string GetDbUser() const { return m_DbUser; }

	const string GetDbPassword() const { return m_DbPassword; }

	const unsigned int GetTimeout() const { return m_Timeout; }

	bool operator==(const DbSettings& other) const
	{
		return other.m_Host == m_Host && other.m_Port == m_Port && other.m_DbName == m_DbName && other.m_DbUser == m_DbUser &&
			   other.m_DbPassword == m_DbPassword && other.m_Timeout == m_Timeout;
	}

	bool operator!=(const DbSettings& other) const
	{
		return other.m_Host != m_Host || other.m_Port != m_Port || other.m_DbName != m_DbName || other.m_DbUser != m_DbUser ||
			   other.m_DbPassword != m_DbPassword || other.m_Timeout != m_Timeout;
	}

	bool FillFromFile(string FileName)
	{
		DbSettings tmpDbSettings;
		ConfigFileReader configReader(FileName);
		if (!configReader.GetParameter("Host", tmpDbSettings.m_Host) || !configReader.GetParameter("Port", tmpDbSettings.m_Port) ||
			!configReader.GetParameter("DbName", tmpDbSettings.m_DbName) ||
			!configReader.GetParameter("DbUser", tmpDbSettings.m_DbUser) ||
			!configReader.GetParameter("DbPassword", tmpDbSettings.m_DbPassword) ||
			!configReader.GetParameter("Timeout", tmpDbSettings.m_Timeout))
		{
			return false;
		}

		tmpDbSettings.m_Host = Cryptography::ConfigFileDecrypt(tmpDbSettings.m_Host);
		tmpDbSettings.m_DbName = Cryptography::ConfigFileDecrypt(tmpDbSettings.m_DbName);
		tmpDbSettings.m_DbUser = Cryptography::ConfigFileDecrypt(tmpDbSettings.m_DbUser);
		tmpDbSettings.m_DbPassword = Cryptography::ConfigFileDecrypt(tmpDbSettings.m_DbPassword);

		*this = tmpDbSettings;
		return true;
	}

	bool SaveToFile(string FileName)
	{
		ConfigFileWriter configWriter(FileName);

		return configWriter.AddPrameter("Host", Cryptography::ConfigFileEncrypt(m_Host)) &&
			   configWriter.AddPrameter("Port", m_Port) &&
			   configWriter.AddPrameter("DbName", Cryptography::ConfigFileEncrypt(m_DbName)) &&
			   configWriter.AddPrameter("DbUser", Cryptography::ConfigFileEncrypt(m_DbUser)) &&
			   configWriter.AddPrameter("DbPassword", Cryptography::ConfigFileEncrypt(m_DbPassword)) &&
			   configWriter.AddPrameter("Timeout", m_Timeout);
	}

	void SetDefaultValues()
	{
		m_Host = DB_HOST;
		m_Port = DB_PORT;
		m_DbName = DB_NAME;
		m_DbUser = DB_USER;
		m_DbPassword = DB_PASSWORD;
		m_Timeout = DB_TIMEOUT;
	}

private:
	string m_Host;
	unsigned int m_Port;
	string m_DbName;
	string m_DbUser;
	string m_DbPassword;
	unsigned int m_Timeout;
};
