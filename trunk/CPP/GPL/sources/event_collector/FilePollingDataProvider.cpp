#include "FilePollingDataProvider.h"
#include <fstream>
#include <sstream>
#include <iostream>
#include <unistd.h>

using namespace std;

FilePollingDataProvider::FilePollingDataProvider( string FileName ):
m_FileName( FileName ),
m_Interrupted( false )
{

}

FilePollingDataProvider::~FilePollingDataProvider( )
{

}

bool FilePollingDataProvider::Run( )
{
    while( !m_Interrupted )
    {
        ifstream file( m_FileName.c_str(), ifstream::in );
        if( !file.is_open( ) )
        {
            usleep( 100000 );
            continue;
        }

        while( !m_Interrupted )
        {
            string line;
            getline( file, line );

            if( file.eof( ) )
            {
                ifstream ifile( m_FileName.c_str(), ifstream::in );
                if( !ifile )
                {
                    break;
                }

                file.clear();
                file.seekg( file.tellg( ), ios::beg );
            }
            else
            {
                // Process messages like this: <14>Nov 10 20:26:56 last message repeated 5 times
                 const string firstToken = "last message repeated";
                 const string lastToken  = "times";
                 size_t firstTokenPos = line.find( firstToken );
                 size_t lastTokenPos  = line.find( lastToken );

                 bool repeatFound = false;
                 size_t repetitionCount = 0;
                 if( string::npos != firstTokenPos && string::npos != lastTokenPos )
                 {
                     string number = line.substr( firstTokenPos + firstToken.length( ) + 1 );
                     size_t spacePos = number.find_first_of( ' ' );
                     if( string::npos != spacePos )
                     {
                         number = number.substr( 0, spacePos );
                         stringstream ss;
                         ss << number;
                         ss >> repetitionCount;

                         repeatFound = true;
                     }
                 }

                 if( repeatFound )
                 {
                     for( size_t i = 0; i < repetitionCount; ++i )
                     {
                         DataProviderListener::DataProviderEvent event( DataProviderListener::DataProviderEvent::Event::DATA, m_PreviousLine );
                         m_Notifier.Notify( event );
                     }
                 }
                 else
                 {
                     DataProviderListener::DataProviderEvent event( DataProviderListener::DataProviderEvent::Event::DATA, line );
                     m_Notifier.Notify( event );
                     m_PreviousLine = line;
                 }
            }

            usleep( 10000 );
        }
    }

    return true;
}

bool FilePollingDataProvider::Stop( )
{
    m_Interrupted = true;
    return true;
}

void FilePollingDataProvider::RegisterListener( DataProviderListener &Listener )
{
    m_Notifier.Register( Listener );
}

void FilePollingDataProvider::UnregisterListener( DataProviderListener &Listener )
{
    m_Notifier.Unregister( Listener );
}

