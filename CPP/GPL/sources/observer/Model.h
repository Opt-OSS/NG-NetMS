#pragma once

#include <string>
#include <map>
#include <list>

using std::string;
using std::map;
using std::list;

struct ModelOption
{
	int		_id;
	int		_modelId;
	int		_type;
	string	_name;
	string	_oid;
	string	_unit;
};

struct Model
{
	int						_id;
	string					_model;
	string					_snmpVersion;
	string					_vendor;
	map<int, ModelOption>	_modelOptions;
	list<int>				_optionIDs;					//is using for compatation
	
	void OidsRenew();

#if 0
	void Print();
#endif
};

