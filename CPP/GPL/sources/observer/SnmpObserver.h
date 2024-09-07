#pragma once

#include <memory>

#include "Database.h"
#include "LogWriter.h"
#include "ObserverOptions.h"
#include "OriginManager.h"

using std::shared_ptr;

class SnmpObserver
{
public:
	SnmpObserver();
	static SnmpObserver& GetInstance();
	int Execute(int argc, char* argv[]);

private:
	void CreateLogger(ObserverOptions& Options);
	bool CreateOriginManager(ObserverOptions& Options);
	bool ParseCmdLineArgs(ObserverOptions& Options, int argc, char* argv[]);
	bool ReadNgnmsHomeEnvVariable();
	bool CreateDbStorage(ObserverOptions& Options);
	bool Update(ObserverOptions& options);
	void Run(ObserverOptions& Options);

	shared_ptr<Database> m_Database;
	shared_ptr<LogWriter> m_Logger;
	unique_ptr<OriginManager> m_Observer;
	bool m_Debug;
	string m_NgnmsHomePath;
};
