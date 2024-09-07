#pragma once

#include <cstdint>
#include <cstring>

class NetFlowHeader_v5
{
public:
	NetFlowHeader_v5() { memset(&m_header, 0, sizeof(header)); }

	NetFlowHeader_v5(const unsigned char* Header) { memcpy(&m_header, Header, sizeof(header)); }

	NetFlowHeader_v5(const NetFlowHeader_v5& other) { m_header = other.m_header; }

	static size_t GetHeaderSize() { return sizeof(header); }

	static uint16_t invertEndianess(uint16_t data) { return ((data >> 8) & 0xff) | ((data & 0xff) << 8); }

	static uint32_t invertEndianess(uint32_t data)
	{
		uint32_t b1 = ((data >> 24) & 0xff);
		uint32_t b2 = ((data >> 16) & 0xff);
		uint32_t b3 = ((data >> 8) & 0xff);
		uint32_t b4 = ((data >> 0) & 0xff);

		return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
	}

	NetFlowHeader_v5& operator=(const NetFlowHeader_v5& other)
	{
		m_header = other.m_header;
		return *this;
	}

	bool operator==(const NetFlowHeader_v5& other) const { return memcmp(&m_header, &other.m_header, sizeof(header)); }

	bool operator!=(const NetFlowHeader_v5& other) const { return 0 != memcmp(&m_header, &other.m_header, sizeof(header)); }

	uint16_t GetVersion() const { return invertEndianess(m_header.version); }

	uint16_t GetCount() const { return invertEndianess(m_header.count); }

	uint32_t GetSysUptime() const { return invertEndianess(m_header.sys_uptime); }

	uint32_t GetUnixSecs() const { return invertEndianess(m_header.unix_secs); }

	uint32_t GetUnixNsecs() const { return invertEndianess(m_header.unix_nsecs); }

	uint32_t GetFlowSequence() const { return invertEndianess(m_header.flow_sequence); }

	uint8_t GetEngineType() const { return m_header.engine_type; }

	uint8_t GetEngineIde() const { return m_header.engine_ide; }

	uint16_t GetSamplingInterval() const { return invertEndianess(m_header.sampling_interval); }

private:
	struct header
	{
		uint16_t version;  // 0-1	 version	NetFlow export format version number
		uint16_t count;	 // 2-3	 count	Number of flows exported in this packet (1-30)
		uint32_t sys_uptime;  // 4-7	 sys_uptime	Current time in milliseconds since the export device booted
		uint32_t unix_secs;	 // 8-11	 unix_secs	Current count of seconds since 0000 UTC 1970
		uint32_t unix_nsecs;  // 12-15 unix_nsecs	Residual nanoseconds since 0000 UTC 1970
		uint32_t flow_sequence;	 // 16-19 flow_sequence	Sequence counter of total flows seen
		uint8_t engine_type;  // 20	 engine_type	Type of flow-switching engine
		uint8_t engine_ide;	 // 21	 engine_id	Slot number of the flow-switching engine
		uint16_t sampling_interval;	 // 22-23 sampling_interval	First two bits hold the sampling mode; remaining 14 bits hold value of sampling interval

	} __attribute__((packed));

private:
	header m_header;
};
