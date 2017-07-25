#include "ApacheFileDP.h"
#include <fstream>
#include <sstream>

using namespace std;

ApacheFileDP::ApacheFileDP( string FileName ):
m_FileName( FileName ),
m_Interrupted( false )
{

}

ApacheFileDP::~ApacheFileDP( )
{

}

bool ApacheFileDP::Run( )
{
    fstream fileStream;
    try
    {
         fileStream.open( m_FileName.c_str(), fstream::in );

         if( !fileStream.is_open( ) )
         {
             return false;
         }
    }
    catch( ... )
    {
        return false;
    }

     while( !fileStream.eof() && !m_Interrupted )
     {
         string line;
         getline( fileStream, line );

         if( line.empty() )
         {
             continue;
         }

         DataProviderListener::DataProviderEvent event( DataProviderListener::DataProviderEvent::Event::DATA, line );
         m_Notifier.Notify( event );
     }

     DataProviderListener::DataProviderEvent event( DataProviderListener::DataProviderEvent::Event::END_OF_DATA );
     m_Notifier.Notify( event );

    fileStream.close( );
    return true;
}

bool ApacheFileDP::Stop( )
{
    m_Interrupted = true;
    return true;
}

void ApacheFileDP::RegisterListener( DataProviderListener &Listener )
{
    m_Notifier.Register( Listener );
}

void ApacheFileDP::UnregisterListener( DataProviderListener &Listener )
{
    m_Notifier.Unregister( Listener );
}
