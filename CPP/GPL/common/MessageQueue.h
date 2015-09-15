#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/wait.h>
#include <mqueue.h>
#include <string>

namespace ngnms
{
	//service message
	const int SERVICE = 0;
	//service code
	const int CODE_TS_END = 0;
	const int CODE_MQ_OVERFLOW = 1;
	
	typedef struct {
		time_t ts;
		int	originID;
		int	devSeverity;
	} P2DBuf;

	
	enum class LinkType {C2P, P2D};		//Collector to Profiler, Profiler to Detector
	enum class OpenMode {OMQ_READ, OMQ_WRITE};

	class MQueue
	{
	public:

		MQueue(const LinkType& lt, const OpenMode& om);
		virtual ~MQueue();

		bool Read(P2DBuf* mBuf);
		bool Write(const P2DBuf* pBuf);
		bool IsOpen();
		void SetSyncMode(bool flag);

		void Print();
		std::string GetStat();
		void ResetStat();
	private:
		mqd_t		_mqfd;
		mq_attr		_mqstat;
		int			_bufLen;
		LinkType	_link;
		bool		_syncMode;
		
		long int	_maxMqCurmsgs;
	};

	void DeleteMQ(const LinkType& lt);

}//namespace
