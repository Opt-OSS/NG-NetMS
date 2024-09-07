#include "SnmpOption.h"

SnmpValue::SnmpValue(const int oid, const SnmpVT& t) : 
	_optionId(oid),
	_type(t)
{
	_value.bigintV = 0;
}