#pragma once

#include "Database.h"
#include <chrono>
#include <memory>
#include <atomic>
#include <mutex>

using std::shared_ptr;

class Profiler
{
	mutable std::recursive_mutex m_Lock; //mutable allows dump() method be const
	std::vector<SnmpValue>		 m_Elements;
	
public:
	friend bool dump(Profiler& p, shared_ptr<Database>& db, const time_t& ts);
	int Add(const int oid, const SnmpVT& t);
	void Update(const int vid, const long val);	//! Provides deadlock in case of std::mutex
};

bool dump(Profiler& p, shared_ptr<Database>& db, const time_t& ts);
