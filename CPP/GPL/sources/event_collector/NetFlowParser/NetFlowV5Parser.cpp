#include "NetFlowV5Parser.h"

using namespace std;

NetFlowV5Parser::NetFlowV5Parser(  ):
m_ReadHeader(true)
{

}

void NetFlowV5Parser::Reset( )
{
	m_Buffer.clear();
	m_ReadHeader = true;
}

void NetFlowV5Parser::Parse( const char * Bytes, size_t Count )
{
	m_Buffer.append(Bytes, Count);

	bool found;
	do
	{
		found = false;
		if(m_ReadHeader && m_Buffer.size() >= NetFlowHeader_v5::GetHeaderSize())
		{
			m_Header = NetFlowHeader_v5(reinterpret_cast<const unsigned char*>( m_Buffer.c_str()));
			m_Buffer.erase( 0, NetFlowHeader_v5::GetHeaderSize());
			m_ReadHeader = false;
			found = true;
		}

		if( !m_ReadHeader )
		{
			size_t recordsSize = m_Header.GetCount() * NetFlowRecord_v5::GetRecordSize();
			if( m_Buffer.size() >= recordsSize )
			{
				m_Packets.push_back( NetFlowPacket_v5( m_Header, reinterpret_cast<const unsigned char*>( m_Buffer.c_str())));
				m_Buffer.erase( 0, recordsSize);
				m_ReadHeader = true;
				found = true;
			}
		}

	}while(found);
}

size_t NetFlowV5Parser::GetNetFlowPacketsCount( )
{
	return m_Packets.size( );
}

vector<NetFlowPacket_v5> NetFlowV5Parser::PeakNetFlowPackets( )
{
	vector<NetFlowPacket_v5> packets = m_Packets;
	m_Packets.clear();
	return packets;
}
