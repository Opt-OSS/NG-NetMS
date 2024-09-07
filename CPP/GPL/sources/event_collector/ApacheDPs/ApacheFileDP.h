#pragma once

#include "IDataProvider.h"

class ApacheFileDP : public IDataProvider
{
public:
	ApacheFileDP(string FileName);
	virtual ~ApacheFileDP();
	bool Run();
	bool Stop();
	void RegisterListener(DataProviderListener &Listener);
	void UnregisterListener(DataProviderListener &Listener);

private:
	string m_FileName;
	bool m_Interrupted;
	Notifier<DataProviderListener, DataProviderListener::DataProviderEvent &> m_Notifier;
};
