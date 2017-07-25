#include "ApacheFilePollingDP.h"
#include <fstream>
#include <sstream>
#include <iostream>
#include <unistd.h>

using namespace std;

ApacheFilePollingDP::ApacheFilePollingDP( string FileName )
{
	m_FilePollReader.SetFileName(FileName);
	m_FilePollReader.RegisterHandlers(this);
}

ApacheFilePollingDP::~ApacheFilePollingDP( )
{

}

void ApacheFilePollingDP::OnReadLine( const std::string& Line )
{
	 DataProviderListener::DataProviderEvent event( DataProviderListener::DataProviderEvent::Event::DATA, Line );
	 m_Notifier.Notify( event );
}

bool ApacheFilePollingDP::Run( )
{
    return m_FilePollReader.Run();
}

bool ApacheFilePollingDP::Stop( )
{
	m_FilePollReader.Stop();
    return true;
}

void ApacheFilePollingDP::RegisterListener( DataProviderListener &Listener )
{
    m_Notifier.Register( Listener );
}

void ApacheFilePollingDP::UnregisterListener( DataProviderListener &Listener )
{
    m_Notifier.Unregister( Listener );
}

