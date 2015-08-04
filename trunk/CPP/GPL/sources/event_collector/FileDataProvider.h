#pragma once

#include "IDataProvider.h"

class FileDataProvider: public IDataProvider
{
    public:
        FileDataProvider( string FileName );
        virtual ~FileDataProvider( );
        bool Run( );
        bool Stop( );
        void RegisterListener( DataProviderListener &Listener );
        void UnregisterListener( DataProviderListener &Listener );

    private:
        string  m_FileName;
        bool    m_Interrupted;
        string  m_PreviousLine;
        Notifier<DataProviderListener, DataProviderListener::DataProviderEvent&> m_Notifier;
};
