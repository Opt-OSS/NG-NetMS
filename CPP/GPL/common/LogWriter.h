#pragma once
#include <memory>
#include <string>
namespace ngnms
{
	using std::string;
	
	enum LogLevel 
	{
		ERROR	= 1,
		WARNING	= 2,
		INFO	= 3 
	};
	
	class LogWriter {
	public:
		LogWriter();
		
		void SetLogFileName(string& LogFile);
		void SetLogLevel(int lvl);
		
        void LogInfo(const string& mess, const string& detail = "");
        void LogWarning(const string& mess, const string& detail = "");
        void LogError(const string& mess, const string& detail = "");
	
		void Log(const LogLevel& lvl, string& mess, const string& detail = "");
	private:
        string _logFile;
		LogLevel _logLevel;
	};
	
}

