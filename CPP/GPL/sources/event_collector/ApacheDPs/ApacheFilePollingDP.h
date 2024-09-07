#pragma once

#include "FilePollReader.h"
#include "IDataProvider.h"

class ApacheFilePollingDP : public IDataProvider, IFilePollReaderHandler
{
public:
	ApacheFilePollingDP(string FileName, std::shared_ptr<Logger> Logger);
	virtual ~ApacheFilePollingDP();
	bool Run();
	bool Stop();
	void RegisterListener(DataProviderListener &Listener);
	void UnregisterListener(DataProviderListener &Listener);

private:
	void OnReadLine(const std::string &Line);

private:
	std::shared_ptr<Logger> m_Logger;
	FilePollReader m_FilePollReader;
	Notifier<DataProviderListener, DataProviderListener::DataProviderEvent &> m_Notifier;
};
