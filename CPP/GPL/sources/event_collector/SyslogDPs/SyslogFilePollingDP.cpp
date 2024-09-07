#include "SyslogFilePollingDP.h"

#include <unistd.h>

#include <fstream>
#include <iostream>
#include <sstream>

using namespace std;

SyslogFilePollingDP::SyslogFilePollingDP(string FileName, std::shared_ptr<Logger> Logger): m_Logger(Logger)
{
	m_FilePollReader.SetFileName(FileName);
	m_FilePollReader.RegisterHandlers(this);
	m_FilePollReader.SetLogger(Logger);
}

SyslogFilePollingDP::~SyslogFilePollingDP()
{
}

void SyslogFilePollingDP::OnReadLine(const std::string &Line)
{
	// Process messages like this: <14>Nov 10 20:26:56 last message repeated 5 times
	const string firstToken = "last message repeated";
	const string lastToken = "times";
	size_t firstTokenPos = Line.find(firstToken);
	size_t lastTokenPos = Line.find(lastToken);

	bool repeatFound = false;
	size_t repetitionCount = 0;
	if (string::npos != firstTokenPos && string::npos != lastTokenPos)
	{
		string number = Line.substr(firstTokenPos + firstToken.length() + 1);
		size_t spacePos = number.find_first_of(' ');
		if (string::npos != spacePos)
		{
			number = number.substr(0, spacePos);
			stringstream ss;
			ss << number;
			ss >> repetitionCount;

			repeatFound = true;
		}
	}

	if (repeatFound)
	{
		for (size_t i = 0; i < repetitionCount; ++i)
		{
			DataProviderListener::DataProviderEvent event(DataProviderListener::DataProviderEvent::Event::DATA, m_PreviousLine);
			m_Notifier.Notify(event);
		}
	}
	else
	{
		DataProviderListener::DataProviderEvent event(DataProviderListener::DataProviderEvent::Event::DATA, Line);
		m_Notifier.Notify(event);
		m_PreviousLine = Line;
	}
}

bool SyslogFilePollingDP::Run()
{
	m_Logger->LogInfo("Start SyslogFilePollingDP");
	for (;;)
	{
		//restart polling in case file moved| deleted| truncated
		if (m_FilePollReader.Run())
		{
			break;
		}
		m_Logger->LogDebug("Restarting....");
		m_FilePollReader.Stop();
	}
	return true;
}

bool SyslogFilePollingDP::Stop()
{
	m_FilePollReader.Stop();
	return true;
}

void SyslogFilePollingDP::RegisterListener(DataProviderListener &Listener)
{
	m_Notifier.Register(Listener);
}

void SyslogFilePollingDP::UnregisterListener(DataProviderListener &Listener)
{
	m_Notifier.Unregister(Listener);
}
