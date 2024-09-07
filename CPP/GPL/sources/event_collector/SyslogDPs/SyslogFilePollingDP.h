#pragma once

#include "FilePollReader.h"
#include "IDataProvider.h"

class SyslogFilePollingDP : public IDataProvider, IFilePollReaderHandler
{
public:
	SyslogFilePollingDP(string FileName, std::shared_ptr<Logger> Logger);
	virtual ~SyslogFilePollingDP();
	bool Run();
	bool Stop();

	void RegisterListener(DataProviderListener &Listener);
	void UnregisterListener(DataProviderListener &Listener);

private:
	void OnReadLine(const std::string &Line);

private:
	std::shared_ptr<Logger> m_Logger;
	FilePollReader m_FilePollReader;
	string m_PreviousLine;
	Notifier<DataProviderListener, DataProviderListener::DataProviderEvent &> m_Notifier;
};
