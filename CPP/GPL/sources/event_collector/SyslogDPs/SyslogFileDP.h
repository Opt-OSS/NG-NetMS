#pragma once

#include "IDataProvider.h"

class SyslogFileDP: public IDataProvider
{
    public:
        SyslogFileDP( string FileName );
        virtual ~SyslogFileDP( );
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
