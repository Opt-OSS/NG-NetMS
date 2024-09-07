#pragma once

#include <atomic>
#include <chrono>
#include <memory>
#include <mutex>

#include "Database.h"

using std::shared_ptr;

class Profiler
{
	mutable std::recursive_mutex m_Lock;  //mutable allows dump() method be const
	std::vector<SnmpValue> m_Elements;

public:
	friend bool dump(Profiler& p, shared_ptr<Database>& db, const time_t& ts);
	int Add(const int oid, const SnmpVT& t);
	void Update(const int vid, const long val, bool _is_nan = false);  //! Provides deadlock in case of std::mutex
};

bool dump(Profiler& p, shared_ptr<Database>& db, const time_t& ts);
