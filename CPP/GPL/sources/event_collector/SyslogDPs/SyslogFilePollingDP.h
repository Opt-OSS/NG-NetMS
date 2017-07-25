#pragma once

#include "IDataProvider.h"
#include "FilePollReader.h"

class SyslogFilePollingDP: public IDataProvider, IFilePollReaderHandler
{
    public:
        SyslogFilePollingDP( string FileName );
        virtual ~SyslogFilePollingDP( );
        bool Run( );
        bool Stop( );
        void RegisterListener( DataProviderListener &Listener );
        void UnregisterListener( DataProviderListener &Listener );

    private:
        void OnReadLine( const std::string& Line );

    private:
        FilePollReader	m_FilePollReader;
        string  		m_PreviousLine;
        Notifier<DataProviderListener, DataProviderListener::DataProviderEvent&> m_Notifier;
};
