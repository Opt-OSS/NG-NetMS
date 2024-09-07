#pragma once

#include <map>
#include <string>
#include <vector>

#include "Profiler.h"
#include "SnmpOption.h"

using namespace std;

enum eVersion
{
	v1 = SNMP_VERSION_1,
	v2c = SNMP_VERSION_2c,
	v2u = SNMP_VERSION_2u,
	v3 = SNMP_VERSION_3
};

enum eRetCode
{
	RET_SUCCESS,
	RET_FAIL,
	RET_ERROR,
	RET_TIMEOUT
};

class Origin
{
public:
	Origin();

	void AddOption(SnmpOption& option);
	void SetId(int id);
	void SetIp(const string& type);
	void SetModelId(const int mid);
	void SetCommunity(const string& comm);
	void SetVersion(const string& version);
	int GetId() const;
	string GetIpAddr() const;
	int GetModelId() const;
	int GetVersion() const;
	vector<SnmpOption>& GetOptions();
	int GetOptionsCount() const;
	int GetMonitorableCount() const;
	string GetCommunity() const;
	bool TestOptions(std::map<int, int>& newOptTypes, std::mutex& mtxOptTypes);
	eRetCode UpdateValues();
	void PrintOptions();

private:
	int m_Id;
	eVersion m_SnmpVersion;
	string m_Community;
	string m_IpAddr;
	int m_ModelId;
	vector<SnmpOption> m_Options;
};
