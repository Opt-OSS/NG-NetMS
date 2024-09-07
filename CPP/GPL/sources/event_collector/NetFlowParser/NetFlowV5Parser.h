#pragma once

#include <string>
#include <vector>

#include "NetFlowPacket_v5.h"

class NetFlowV5Parser
{
public:
	NetFlowV5Parser();
	void Reset();
	void Parse(const char* Bytes, size_t Count);
	size_t GetNetFlowPacketsCount();
	std::vector<NetFlowPacket_v5> PeakNetFlowPackets();

private:
	bool m_ReadHeader;
	NetFlowHeader_v5 m_Header;
	std::string m_Buffer;
	std::vector<NetFlowPacket_v5> m_Packets;
};
