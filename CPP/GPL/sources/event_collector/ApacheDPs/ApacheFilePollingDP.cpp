#include "ApacheFilePollingDP.h"
#include <fstream>
#include <sstream>
#include <iostream>
#include <unistd.h>

using namespace std;

ApacheFilePollingDP::ApacheFilePollingDP( string FileName , std::shared_ptr<Logger> Logger):
		m_Logger(Logger)
{
	m_FilePollReader.SetFileName(FileName);
	m_FilePollReader.RegisterHandlers(this);
	m_FilePollReader.SetLogger(Logger);
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
	m_Logger->LogInfo("Start ApacheFilePollingDP");
	for (;;) {
		//restart polling in case file moved| deleted| truncated
		if (m_FilePollReader.Run()) {
			break;
		}
		m_Logger->LogDebug("Restarting....");
		m_FilePollReader.Stop();
	}
	m_Logger->LogDebug("Stopping....");
	return true;
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

