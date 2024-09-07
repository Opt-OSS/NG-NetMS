#pragma once

#include <map>
#include <memory>
#include <stack>
#include <thread>

#include "Database.h"
#include "LogWriter.h"
#include "Origin.h"
#include "Profiler.h"

using namespace std;

class OriginManager
{
public:
	OriginManager(shared_ptr<Database>& db, shared_ptr<LogWriter>& logger, int imax);
	bool LoadOrigins();
	bool LoadOriginThreads();
	void Run();

private:
	shared_ptr<Database> m_Database;
	shared_ptr<LogWriter> m_Logger;
	Profiler m_Profiler;
	vector<std::thread> m_Threads;
	vector<Origin> m_Origins;
	int m_MaxInterval;
};
