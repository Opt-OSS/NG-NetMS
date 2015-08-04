#include "FileDataProvider.h"
#include <fstream>
#include <sstream>

using namespace std;

FileDataProvider::FileDataProvider( string FileName ):
m_FileName( FileName ),
m_Interrupted( false )
{

}

FileDataProvider::~FileDataProvider( )
{

}

bool FileDataProvider::Run( )
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

         if( !line.size( ) )
         {
             continue;
         }

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

     DataProviderListener::DataProviderEvent event( DataProviderListener::DataProviderEvent::Event::END_OF_DATA );
     m_Notifier.Notify( event );

    fileStream.close( );
    return true;
}

bool FileDataProvider::Stop( )
{
    m_Interrupted = true;
    return true;
}

void FileDataProvider::RegisterListener( DataProviderListener &Listener )
{
    m_Notifier.Register( Listener );
}

void FileDataProvider::UnregisterListener( DataProviderListener &Listener )
{
    m_Notifier.Unregister( Listener );
}
