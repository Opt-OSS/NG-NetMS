#pragma once

#include "IDataProvider.h"

class FilePollingDataProvider: public IDataProvider
{
    public:
        FilePollingDataProvider( string FileName );
        virtual ~FilePollingDataProvider( );
        bool Run( );
        bool Stop( );
        void RegisterListener( DataProviderListener &Listener );
        void UnregisterListener( DataProviderListener &Listener );

    private:
        string  m_FileName;
        string  m_PreviousLine;
        bool    m_Interrupted;
        Notifier<DataProviderListener, DataProviderListener::DataProviderEvent&> m_Notifier;
};
