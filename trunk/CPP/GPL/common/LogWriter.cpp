/* 
 * File:   LogFileWriter.cpp
 * Author: cornet
 * 
 * Created on July 2, 2015, 8:20 PM
 */

#include "LogWriter.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <time.h>
#include <condition_variable>
#include <iostream>
#include <random>
#include <thread>
#include <mutex>
#include <queue>

std::mutex              g_lockprint;
std::mutex              g_lockqueue;
std::condition_variable g_queuecheck;
std::queue<std::string> g_messages;
bool                    g_done;
bool                    g_notified;

namespace ngnms
{
	using std::ofstream;
	using std::fstream;
	using std::stringstream;
	using std::cout;
	using std::endl;

	const std::string currentDateTime() {
		time_t     now = time(0);
		struct tm  tstruct;
		char       buf[80];
		tstruct = *localtime(&now);
		// Visit http://en.cppreference.com/w/cpp/chrono/c/strftime
		// for more information about date/time format
		strftime(buf, sizeof(buf), "%Y-%m-%d.%X", &tstruct);

		return buf;
	}

	class FileLogFileWriter
	{
	public:
		FileLogFileWriter( string FileName, string Message )
		{
			if( 0 == FileName.length( ) )
			{
				return;
			}
			try
			{
				ofstream logfile;
				logfile.open ( FileName.c_str( ), fstream::app );
				if( !logfile.is_open() )
				{
					return;
				}

				logfile << "[" << currentDateTime() << "] " << Message;
				logfile.close();
			}
			catch( ... )
			{
				// Don't care!
			}
		}
	};

	
	LogWriter::LogWriter() :
		_logLevel(LogLevel::ERROR)
	{
	}
	
	void LogWriter::SetLogFileName( string& LogFile )
	{
		_logFile = LogFile;
	}

	void LogWriter::SetLogLevel(int lvl)
	{
		if (lvl < LogLevel::ERROR || lvl > LogLevel::INFO)
			return;
		
		_logLevel = LogLevel(lvl);
	}
	
	void LogWriter::LogInfo(const string& mess, const string& detail)
	{
		if (_logLevel < LogLevel::INFO)
			return;
			
		stringstream ss;
		ss << mess << endl;
		FileLogFileWriter logger(_logFile, ss.str());
		cout << ss.str();
	}

	void LogWriter::LogWarning(const string& mess, const string& detail)
	{
		if (_logLevel < LogLevel::WARNING)
			return;
		
		stringstream ss;
		ss << "Warning: " << mess;
		if (_logLevel > LogLevel::ERROR)
			ss << detail;			
		
		ss << endl;
		FileLogFileWriter logger( _logFile, ss.str() );
		cout << ss.str();
	}

	void LogWriter::LogError(const string& mess, const string& detail)
	{
		stringstream ss;
		ss << "Error: " << mess;
		if (_logLevel > LogLevel::ERROR)
			ss << detail;
		
		ss << endl;
		FileLogFileWriter logger( _logFile, ss.str() );
		cout << ss.str();
	}

	void LogWriter::Log(const LogLevel& lvl, string& mess, const string& detail)
	{
		if (_logLevel < lvl)
			return;
		
		switch(lvl)
		{
			case LogLevel::INFO:
				LogInfo(mess, detail);
				break;
			case LogLevel::WARNING:
				LogWarning(mess, detail);	//TODO
				break;
			case LogLevel::ERROR:
				LogError(mess, detail);
				break;
		}
	}
}

#if 0
void loggerFunc()
{
     // Start message
     {
          std::unique_lock<std::mutex> locker(g_lockprint);
          std::cout << "[logger]\trunning..." << std::endl;
     }
     // while a signal will not be resave
     while(!g_done)
     {
          std::unique_lock<std::mutex> locker(g_lockqueue);
          while(!g_notified) //if fake wakeup
               g_queuecheck.wait(locker);
          // process the queue
          while(!g_messages.empty())
          {
               std::unique_lock<std::mutex> locker(g_lockprint);
               std::cout << "[logger]\tprocessing error:  " << g_messages.front()  << std::endl;
               g_messages.pop();
          }
          g_notified = false;
     }
}
#endif