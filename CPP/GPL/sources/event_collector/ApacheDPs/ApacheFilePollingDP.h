#pragma once

#include "IDataProvider.h"
#include "FilePollReader.h"

class ApacheFilePollingDP: public IDataProvider, IFilePollReaderHandler
{
    public:
		ApacheFilePollingDP( string FileName );
        virtual ~ApacheFilePollingDP( );
        bool Run( );
        bool Stop( );
        void RegisterListener( DataProviderListener &Listener );
        void UnregisterListener( DataProviderListener &Listener );

    private:
        void OnReadLine( const std::string& Line );

    private:
        FilePollReader	m_FilePollReader;
        Notifier<DataProviderListener, DataProviderListener::DataProviderEvent&> m_Notifier;
};
