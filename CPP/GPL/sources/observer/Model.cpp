#include "Model.h"

#include <list>

#if 0
	#include <iostream>

void Model::Print()
{
    if (_id == 6)
        std::cout << "[##]" << std::endl;
    
    std::cout << "[" << _id << "]" << std::endl;
    for (auto& option : _modelOptions)
	{
		std::cout << " " << option.second._id << " " << option.second._oid << std::endl;
	}
}
#endif

void Model::OidsRenew()
{
	_optionIDs.clear();
	for (auto& option : _modelOptions)
	{
		_optionIDs.push_back(option.first);
	}
}
