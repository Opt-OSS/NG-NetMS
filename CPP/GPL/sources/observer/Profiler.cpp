#include "Profiler.h"
#include <iostream>
#include <atomic>


int Profiler::Add(const int oid, const SnmpVT& t)
{
	std::lock_guard<std::recursive_mutex> locker(m_Lock);
	m_Elements.push_back(SnmpValue(oid, t));
	return m_Elements.size() - 1;	//return element index
}
	
void Profiler::Update(const int vid, const long val)	//! Provides deadlock in case of std::mutex
{
	std::lock_guard<std::recursive_mutex> locker(m_Lock);
	m_Elements[vid]._value.bigintV = val;
}


bool dump(Profiler& p, shared_ptr<Database>& db, const time_t& ts)
{
    std::lock_guard<std::recursive_mutex> locker(p.m_Lock);
    for (auto& e : p.m_Elements)
        db->SetValue(e, ts);
	
	return db->Save();
}
