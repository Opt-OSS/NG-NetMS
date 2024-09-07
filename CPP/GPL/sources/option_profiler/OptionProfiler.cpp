#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>
#include <chrono>
#include <ctime>
#include <iostream>
#include <memory>
#include <sstream>
#include <thread>

#include "Configuration.h"
#include "Database.h"
#include "Logger.h"
#include "OptPrfOptions.h"

using namespace std;
using namespace std::chrono;

namespace fs = boost::filesystem;

static vector<int> PROFILING_INTERVALS = {
	15, /* 15 sec */
	60, /* 1 min */
	900, /* 15 min */
	3600 /* 1 hour */
};

class OptionProfiler
{
public:
	static OptionProfiler& GetInstance()
	{
		static OptionProfiler collector;
		return collector;
	}

	int Execute(int argc, char* argv[])
	{
		OptPrfOptions options;
		if (!options.Parse(argc, argv))
		{
			return -1;
		}

		cout << "Option Profiler " << VERSION_MAJOR << "." << VERSION_MINOR << " " << BUILD_DATE << " " << BUILD_TIME;
		CreateLogger();

		if (!ReadNgnmsHomeEnvVariable())
		{
			return -2;
		}

		SetupLogFile(options);

		if (!CreateDbStorage(options))
		{
			return -3;
		}

		ProcessingLoop(options);
		return 0;
	}

private:
	void CreateLogger() { m_Logger = shared_ptr<Logger>(new Logger()); }

	void SetupLogFile(OptPrfOptions& Options)
	{
		string logFileName = Options.GetLogFile();

		if ('/' != logFileName[0])
		{
			logFileName = m_NgnmsHomePath + logFileName;
		}

		m_Logger->SetLogFileName(logFileName);
	}

	bool ReadNgnmsHomeEnvVariable()
	{
		char* ngnmsHome = getenv(HOME_ENV.c_str());
		if (nullptr == ngnmsHome)
		{
			m_Logger->LogInfo("NGNMS_HOME variable is not set");
			return true;
		}

		m_NgnmsHomePath = ngnmsHome;
		if (m_NgnmsHomePath[0] != '/')
		{
			stringstream ss;
			ss << "Wrong setting NGNMS_HOME = " << m_NgnmsHomePath;
			m_Logger->LogError(ss.str());

			return false;
		}

		fs::path data_dir(m_NgnmsHomePath);
		if (!fs::is_directory(data_dir))
		{
			stringstream ss;
			ss << "Should contain directory NGNMS_HOME = " << m_NgnmsHomePath;
			m_Logger->LogError(ss.str());

			return false;
		}

		if (!fs::exists(data_dir))
		{
			stringstream ss;
			ss << "Directory not exist NGNMS_HOME = " << m_NgnmsHomePath;
			m_Logger->LogError(ss.str());

			return false;
		}

		if ('/' != m_NgnmsHomePath[m_NgnmsHomePath.length() - 1])
		{
			m_NgnmsHomePath += '/';
		}

		stringstream ss;
		ss << "NGNMS_HOME = " << m_NgnmsHomePath;

		m_Logger->LogInfo(ss.str());

		return true;
	}

	bool CreateDbStorage(OptPrfOptions& Options)
	{
		m_Database = std::make_shared<Database>();

		DbSettings dbSettings;

		string dbSettingsFileName = Options.GetOptionsFile();
		if ('/' != dbSettingsFileName[0])
		{
			dbSettingsFileName = m_NgnmsHomePath + dbSettingsFileName;
		}

		if (!boost::filesystem::exists(dbSettingsFileName))
		{
			stringstream ss;
			ss << "DB settings file not exist! Path = " << dbSettingsFileName;
			m_Logger->LogError(ss.str());
			return false;
		}

		stringstream ss;
		ss << "DB Settings File = " << dbSettingsFileName;
		m_Logger->LogInfo(ss.str());
		if (!dbSettings.FillFromFile(dbSettingsFileName))
		{
			m_Logger->LogError("Failed to read DB configuration file!");
			return false;
		}

		bool connected = false;
		for (int i = 0; i < 1000; ++i)
		{
			if (!m_Database->Connect(dbSettings))
			{
				sleep(1);
				continue;
			}
			else
			{
				connected = true;
				break;
			}
		}

		if (!connected)
		{
			m_Logger->LogError("Can't establish connection to the DB!");
			return false;
		}

		return true;
	}

	void ProcessingLoop(OptPrfOptions& options)
	{
		if (options.GetDrop())
		{
			stringstream ss;
			ss << "Initial profiling started" << endl;
			m_Logger->LogInfo(ss.str());

			DbReturnCode rc = m_Database->InitialProfiling(PROFILING_INTERVALS);
			if (rc.IsFail())
			{
				stringstream ss;
				ss << "Database::InitialProfiling error = " << rc.GetDetails() << endl;
				m_Logger->LogError(ss.str());
			}

			{
				stringstream ss;
				ss << "Initial profiling finished" << endl;
				m_Logger->LogInfo(ss.str());
			}
		}
		else
		{
			DbReturnCode rc = m_Database->CreateTables(PROFILING_INTERVALS);
			if (rc.IsFail())
			{
				stringstream ss;
				ss << "Database::CreateTables error = " << rc.GetDetails() << endl;
				m_Logger->LogError(ss.str());
			}
		}

		// Calculate first profiling point
		map<int, time_t> profiling_point;
		time_t time_now = system_clock::to_time_t(system_clock::now());
		for (int interval : PROFILING_INTERVALS)
		{
			profiling_point[interval] = time_now + (interval - time_now % interval);
		}

		// Profiling loop
		for (;;)
		{
			vector<pair<time_t, int> > makeProfileInterval;
			time_t time_now = system_clock::to_time_t(system_clock::now());
			for (int interval : PROFILING_INTERVALS)
			{
				if (time_now >= profiling_point[interval])
				{
					makeProfileInterval.push_back(make_pair(profiling_point[interval], interval));
					time_t next_profiling = time_now + (interval - time_now % interval);
					profiling_point[interval] =
						(profiling_point[interval] != next_profiling) ? next_profiling : next_profiling + interval;
				}
			}

			if (makeProfileInterval.empty())
			{
				this_thread::sleep_for(chrono::seconds(1));
			}
			else
			{
				for (auto& profileInterval : makeProfileInterval)
				{
					DbReturnCode rc = m_Database->ProfileLastInterval(profileInterval.first, profileInterval.second);
					if (rc.IsFail())
					{
						stringstream ss;
						ss << "Database::ProfileLastInterval error = " << rc.GetDetails() << endl;
						m_Logger->LogError(ss.str());
					}
				}
			}
		}
	}

private:
	shared_ptr<Database> m_Database;
	shared_ptr<Logger> m_Logger;
	string m_NgnmsHomePath;
};

int main(int argc, char* argv[])
{
	return OptionProfiler::GetInstance().Execute(argc, argv);
}
