#include "Logger.h"

#include <fstream>
#include <iostream>
#include <sstream>
#include <utility>

class FileLogger
{
public:
	FileLogger(string FileName, string Message)
	{
		if (0 == FileName.length())
		{
			return;
		}
		try
		{
			ofstream logfile;
			logfile.open(FileName.c_str(), std::fstream::app);
			if (!logfile.is_open())
			{
				return;
			}

			logfile << Message;
			logfile.close();
		}
		catch (...)
		{
			// Don't care!
		}
	}
};

Logger::Logger()
{
}

void Logger::SetLogFileName(string LogFile)
{
	m_LogFile = std::move(LogFile);
}

void Logger::LogInfo(string Message)
{
	stringstream ss;
	ss << Message << endl;
	FileLogger logger(m_LogFile, ss.str());
	cout << ss.str();
}

void Logger::LogDebug(string Message)
{
	stringstream ss;
	ss << Message << endl;
	FileLogger logger(m_LogFile, ss.str());
	cout << ss.str();
}

void Logger::LogError(string Message)
{
	stringstream ss;
	ss << "Error: " << Message << endl;
	FileLogger logger(m_LogFile, ss.str());
	cout << ss.str();
}
