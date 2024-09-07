#pragma once

#include <string>

#include "Cryptography.h"
#include "TimeInterval.h"

using namespace std;

class DiscoverySettings
{
public:
	DiscoverySettings() {}
	DiscoverySettings(
		const string& SeedHosts,
		const string& UserName,
		const string& Password,
		const string& EnablePassword,
		const string& SnmpReadCommunity,
		const string& HostType,
		const string& Access
	):
		m_SeedHosts(SeedHosts),
		m_UserName(UserName), m_Password(Password), m_EnablePassword(EnablePassword), m_SnmpReadCommunity(SnmpReadCommunity),
		m_HostType(HostType), m_Access(Access)
	{
	}

	const string& GetSeedHosts() const { return m_SeedHosts; }

	const string& GetUserName() const { return m_UserName; }

	const string& GetPassword() const { return m_Password; }

	const string& GetEnablePassword() const { return m_EnablePassword; }

	const string& GetSnmpReadCommunity() const { return m_SnmpReadCommunity; }

	const string& GetHostType() const { return m_HostType; }

	const string& GetAccess() const { return m_Access; }

	bool operator==(const DiscoverySettings& other) const
	{
		return other.m_SeedHosts == m_SeedHosts && other.m_UserName == m_UserName && other.m_Password == m_Password &&
			   other.m_EnablePassword == m_EnablePassword && other.m_SnmpReadCommunity == m_SnmpReadCommunity &&
			   other.m_HostType == m_HostType && other.m_Access == m_Access;
	}

	bool operator!=(const DiscoverySettings& other) const
	{
		return other.m_SeedHosts != m_SeedHosts || other.m_UserName != m_UserName || other.m_Password != m_Password ||
			   other.m_EnablePassword != m_EnablePassword || other.m_SnmpReadCommunity != m_SnmpReadCommunity ||
			   other.m_HostType != m_HostType || other.m_Access != m_Access;
	}

private:
	string m_SeedHosts;
	string m_UserName;
	string m_Password;
	string m_EnablePassword;
	string m_SnmpReadCommunity;
	string m_HostType;
	string m_Access;
};
