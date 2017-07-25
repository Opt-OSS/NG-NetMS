#pragma once

#include "NetFlowHeader_v5.h"
#include "NetFlowRecord_v5.h"
#include <list>

class NetFlowPacket_v5
{
public:
	NetFlowPacket_v5( NetFlowHeader_v5& Header, const unsigned char* Records ):
	m_Header(Header)
	{
		const NetFlowRecord_v5* records = reinterpret_cast<const NetFlowRecord_v5*>(Records);
		for( size_t i = 0; i < m_Header.GetCount(); ++i )
		{
			m_Records.push_back(records[i]);
		}
	}

	NetFlowPacket_v5( const NetFlowPacket_v5& other ) = default;
	NetFlowPacket_v5& operator=( const NetFlowPacket_v5& other ) = default;

	bool operator==( const NetFlowPacket_v5& other ) const
	{
		return m_Header == other.m_Header &&
			   m_Records == other.m_Records;
	}

	bool operator!=( const NetFlowPacket_v5& other ) const
	{
		return !operator==( other );
	}

	const NetFlowHeader_v5& GetHeader() const
	{
		return m_Header;
	}

	size_t GetRecordCount() const
	{
		return m_Records.size();
	}

	const std::list<NetFlowRecord_v5>& GetRecords( )
	{
		return m_Records;
	}

private:
	NetFlowHeader_v5			m_Header;
	std::list<NetFlowRecord_v5>	m_Records;

};
