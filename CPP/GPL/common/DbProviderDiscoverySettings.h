#pragma once
#include <map>
#include <vector>

#include "DbReturnCode.h"
#include "DiscoverySettings.h"

using namespace std;

template<typename Type> class DbProviderDiscoverySettings
{
private:
	static constexpr auto GEN_SETTINGS_SEEDHOST = "seedHost";
	static constexpr auto GEN_SETTINGS_USERNAME = "username";
	static constexpr auto GEN_SETTINGS_PASSWORD = "password";
	static constexpr auto GEN_SETTINGS_ENPASSWORD = "enpassword";
	static constexpr auto GEN_SETTINGS_COMMUNITY = "community";
	static constexpr auto GEN_SETTINGS_HOSTTYPE = "hostType";
	static constexpr auto GEN_SETTINGS_ACCESS = "type access";

public:
	DbProviderDiscoverySettings(Type& DbProvider): m_DbProvider(DbProvider) {}

	DbReturnCode SetDiscoverySettings(DiscoverySettings& Settings)
	{
		vector<pair<string, string>> values;
		values.push_back(make_pair(GEN_SETTINGS_SEEDHOST, Settings.GetSeedHosts()));
		values.push_back(make_pair(GEN_SETTINGS_USERNAME, Settings.GetUserName()));
		values.push_back(make_pair(GEN_SETTINGS_PASSWORD, Settings.GetPassword()));
		values.push_back(make_pair(GEN_SETTINGS_ENPASSWORD, Settings.GetEnablePassword()));
		values.push_back(make_pair(GEN_SETTINGS_COMMUNITY, Settings.GetSnmpReadCommunity()));
		values.push_back(make_pair(GEN_SETTINGS_HOSTTYPE, Settings.GetHostType()));
		values.push_back(make_pair(GEN_SETTINGS_ACCESS, Settings.GetAccess()));

		for (auto& item : values)
		{
			DbReturnCode rc = m_DbProvider.SetGeneralEncryptedSetting(item.first, item.second);
			if (rc.IsFail())
			{
				return rc;
			}
		}

		return DbReturnCode(DbReturnCode::Code::OK);
	}

	DbReturnCode GetDiscoverySettings(DiscoverySettings& Settings)
	{
		vector<string> names{
			GEN_SETTINGS_SEEDHOST,
			GEN_SETTINGS_USERNAME,
			GEN_SETTINGS_PASSWORD,
			GEN_SETTINGS_ENPASSWORD,
			GEN_SETTINGS_COMMUNITY,
			GEN_SETTINGS_HOSTTYPE,
			GEN_SETTINGS_ACCESS};

		map<string, string> values;
		for (string name : names)
		{
			string value;
			DbReturnCode rc = m_DbProvider.GetGeneralEncryptedSetting(name, value);
			if (rc.IsFail())
			{
				return rc;
			}

			values[name] = value;
		}

		Settings = DiscoverySettings(
			values[GEN_SETTINGS_SEEDHOST],
			values[GEN_SETTINGS_USERNAME],
			values[GEN_SETTINGS_PASSWORD],
			values[GEN_SETTINGS_ENPASSWORD],
			values[GEN_SETTINGS_COMMUNITY],
			values[GEN_SETTINGS_HOSTTYPE],
			values[GEN_SETTINGS_ACCESS]
		);

		return DbReturnCode(DbReturnCode::Code::OK);
	}

private:
	Type& m_DbProvider;
};
