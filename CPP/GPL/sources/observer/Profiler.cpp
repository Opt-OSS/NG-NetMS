#include "Profiler.h"

#include <atomic>
#include <iostream>

int Profiler::Add(const int oid, const SnmpVT& t)
{
	std::lock_guard<std::recursive_mutex> locker(m_Lock);
	m_Elements.push_back(SnmpValue(oid, t));
	return m_Elements.size() - 1;  //return element index
}

void Profiler::Update(const int vid, const long val, bool _is_nan)	//! Provides deadlock in case of std::mutex
{
	std::lock_guard<std::recursive_mutex> locker(m_Lock);
	m_Elements[vid]._value.bigintV = val;
	m_Elements[vid]._is_nan = _is_nan;
}

bool dump(Profiler& p, shared_ptr<Database>& db, const time_t& ts)
{
	std::lock_guard<std::recursive_mutex> locker(p.m_Lock);
	for (auto& e : p.m_Elements)
	{
		if (e._is_nan)
			continue;
		db->SetValue(e, ts);
	}

	return db->Save();
}
