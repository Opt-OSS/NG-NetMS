#pragma once

#include <cstdint>
#include <cstring>

class NetFlowRecord_v5
{
public:
	NetFlowRecord_v5( )
	{
		memset( &m_record,0, sizeof(record) );
	}

	NetFlowRecord_v5( const unsigned char* Header )
	{
		memcpy( &m_record,Header, sizeof(record) );
	}

	NetFlowRecord_v5( const NetFlowRecord_v5& other )
	{
		m_record = other.m_record;
	}

	static size_t GetRecordSize( )
	{
		return sizeof(record);
	}

	static uint16_t invertEndianess( uint16_t data )
	{
		return (( data >> 8) & 0xff) | (( data & 0xff) << 8 );
	}

	static uint32_t invertEndianess( uint32_t data )
	{
		uint32_t b1 = ((data >> 24) & 0xff);
		uint32_t b2 = ((data >> 16) & 0xff);
		uint32_t b3 = ((data >> 8) & 0xff);
		uint32_t b4 = ((data >> 0) & 0xff);

		return (b4 << 24) | (b3 << 16) | (b2 << 8 ) | b1;
	}

	NetFlowRecord_v5& operator=( const NetFlowRecord_v5& other )
	{
		m_record = other.m_record;
		return *this;
	}

	bool operator==( const NetFlowRecord_v5& other ) const
	{
		return memcmp( &m_record, &other.m_record, sizeof(record));
	}

	bool operator!=( const NetFlowRecord_v5& other ) const
	{
		return 0 != memcmp( &m_record, &other.m_record, sizeof(record));
	}

	uint32_t GetSrcAddr() const
	{
		return invertEndianess( m_record.srcaddr );
	}

	uint32_t GetDstAddr() const
	{
		return invertEndianess( m_record.dstaddr );
	}

	uint32_t GetNextHop() const
	{
		return invertEndianess( m_record.nexthop );
	}

	uint16_t GetInput() const
	{
		return invertEndianess( m_record.input );
	}

	uint16_t GetOutput() const
	{
		return invertEndianess( m_record.output );
	}

	uint32_t GetDPkts() const
	{
		return invertEndianess( m_record.dPkts );
	}

	uint32_t GetDOctets() const
	{
		return invertEndianess( m_record.dOctets );
	}

	uint32_t GetFirst() const
	{
		return invertEndianess( m_record.first );
	}

	uint32_t GetLast() const
	{
		return invertEndianess( m_record.last );
	}

	uint16_t GetSrcPort() const
	{
		return invertEndianess( m_record.srcport );
	}

	uint16_t GetDstPort() const
	{
		return invertEndianess( m_record.dstport );
	}

	uint8_t GetTcpFlags() const
	{
		return m_record.tcp_flags;
	}

	uint8_t GetProt() const
	{
		return m_record.prot;
	}

	uint8_t GetTOS() const
	{
		return m_record.tos;
	}

	uint16_t GetSrcAS() const
	{
		return invertEndianess(m_record.src_as );
	}

	uint16_t GetDstAS() const
	{
		return invertEndianess(m_record.dst_as );
	}

	uint8_t GetSrcMask() const
	{
		return m_record.src_mask;
	}

	uint8_t GetDstMask() const
	{
		return m_record.dst_mask;
	}

private:
	struct record
	{
		uint32_t srcaddr;	// 0-3	srcaddr	Source IP address
		uint32_t dstaddr;	// 4-7	dstaddr	Destination IP address
		uint32_t nexthop;	// 8-11	nexthop	IP address of next hop router
		uint16_t input;		// 12-13	input	SNMP index of input interface
		uint16_t output;	// 14-15	output	SNMP index of output interface
		uint32_t dPkts;		// 16-19	dPkts	Packets in the flow
		uint32_t dOctets;	// 20-23	dOctets	Total number of Layer 3 bytes in the packets of the flow
		uint32_t first;		// 24-27	first	SysUptime at start of flow
		uint32_t last;		// 28-31	last	SysUptime at the time the last packet of the flow was received
		uint16_t srcport;	// 32-33	srcport	TCP/UDP source port number or equivalent
		uint16_t dstport;	// 34-35	dstport	TCP/UDP destination port number or equivalent
		uint8_t  pad1;	 	// 36	pad1	Unused (zero) bytes
		uint8_t  tcp_flags;	// 37	tcp_flags	Cumulative OR of TCP flags
		uint8_t  prot;		// 38	prot	IP protocol type (for example, TCP = 6; UDP = 17)
		uint8_t  tos;		// 39	tos	IP type of service (ToS)
		uint16_t src_as;	// 40-41	src_as	Autonomous system number of the source, either origin or peer
		uint16_t dst_as;	// 42-43	dst_as	Autonomous system number of the destination, either origin or peer
		uint8_t  src_mask;	// 44	src_mask	Source address prefix mask bits
		uint8_t  dst_mask;	// 45	dst_mask	Destination address prefix mask bits
		uint16_t pad2;		// 46-47	pad2	Unused (zero) bytes

	} __attribute__ ((packed));

private:
	record m_record;
};
