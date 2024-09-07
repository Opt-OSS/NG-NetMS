#pragma once

#include <net-snmp/net-snmp-config.h>
#include <net-snmp/types.h>

#include <map>
#include <string>

using std::string;

enum SnmpVT
{
	UNKNOWN = 0,
	BIGINT = 1,
	DOUBLE = 2,
	STRING = 3
};

union uValue
{
	long bigintV;
	double doubleV;

	bool operator==(const uValue& other) const { return this->bigintV == other.bigintV && this->doubleV == other.doubleV; }
};

struct SnmpValue
{
	SnmpValue(const int oid, const SnmpVT& t);

	int _optionId;
	SnmpVT _type;
	uValue _value;
	bool _is_nan = false;
};

struct SnmpOption
{
	int _id;
	string _oid;
	bool _track;
	int _modelOptionId;
	int _originId;

	int _valueId;
	SnmpVT _optionType;
	uValue _value;

	bool operator==(const SnmpOption& other) const
	{
		return this->_id == other._id && this->_oid == other._oid && this->_track == other._track &&
			   this->_modelOptionId == other._modelOptionId && this->_originId == other._originId &&
			   this->_valueId == other._valueId && this->_optionType == other._optionType && this->_value == other._value;
	}
};

typedef std::map<int, SnmpOption> OptionMap;
