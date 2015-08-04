#include "TcpDataProvider.h"

TcpDataProvider::TcpDataProvider( int Port ):
m_Port( Port ),
m_Interrupted( false )
{

}

TcpDataProvider::~TcpDataProvider( )
{

}

bool TcpDataProvider::Run( )
{
    try
    {
        boost::asio::io_service io_service;
        tcp::acceptor acceptor( io_service, tcp::endpoint( tcp::v4(), m_Port ) );

        while( !m_Interrupted )
        {
            m_Socket = shared_ptr<tcp::socket>( new tcp::socket( io_service ) );

            acceptor.accept( *( m_Socket.get() ) );

            boost::system::error_code ignored_error;
            boost::array<char, 100*1024> buf;
            boost::system::error_code error;
            size_t len = m_Socket->read_some( boost::asio::buffer( buf ), error);
            buf.data()[ len ] = '\0';

            string line( buf.data() );
            DataProviderListener::DataProviderEvent event( DataProviderListener::DataProviderEvent::Event::DATA, line );
            m_Notifier.Notify( event );
        }
    }
    catch( std::exception& e )
    {
        if( !m_Interrupted  )
        {
            std::cerr << e.what() << std::endl;
        }
    }

    if( m_Interrupted )
    {
        return true;
    }

    return false;
}

bool TcpDataProvider::Stop( )
{
    m_Interrupted = true;
    if( m_Socket.get() )
    {
        m_Socket->shutdown( boost::asio::socket_base::shutdown_both );
    }
    return true;
}

void TcpDataProvider::RegisterListener( DataProviderListener &Listener )
{
    m_Notifier.Register( Listener );
}

void TcpDataProvider::UnregisterListener( DataProviderListener &Listener )
{
    m_Notifier.Unregister( Listener );
}
