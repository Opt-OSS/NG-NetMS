#include "MessageQueue.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/wait.h>
#include <mqueue.h>
#include <string>
#include <iostream>
#include <sstream>      // std::stringstream


namespace ngnms
{

	#define PMODE   0655
	#define MAXMSG  1000

	using std::string;
	const string QFileC2P = "/c2p";
	const string QFileP2D = "/p2d";


	MQueue::MQueue(const LinkType& link, const OpenMode& mode) :
		_syncMode(false)
	{
		_bufLen = sizeof(P2DBuf);
		_link = link;

		struct mq_attr attr;
		attr.mq_maxmsg = MAXMSG;
		attr.mq_msgsize = _bufLen;

		switch (link)
		{
			case LinkType::C2P:
			{
				switch (mode)
				{
					case OpenMode::READ:
						_mqfd = mq_open(QFileC2P.c_str(), O_RDONLY|O_CREAT, PMODE, &attr);
						break;
					case OpenMode::WRITE:
						_mqfd = mq_open(QFileC2P.c_str(), O_WRONLY|O_CREAT, PMODE, &attr);
						break;
				}
			}break;
			case LinkType::P2D:
			{
				switch (mode)
				{
					case OpenMode::READ:
						_mqfd = mq_open(QFileP2D.c_str(), O_RDONLY|O_CREAT, PMODE, &attr);
						break;
					case OpenMode::WRITE:
						_mqfd = mq_open(QFileP2D.c_str(), O_WRONLY|O_CREAT, PMODE, &attr);
						break;
				}
			}break;
		}
	}


	MQueue::~MQueue() 
	{
		mq_close(_mqfd);		//close the connection to the message queue.
	}


	bool MQueue::IsOpen()
	{
		if(_mqfd == -1)
			return false;

		return true;
	}

	void MQueue::SetSyncMode(bool flag)
	{
		_syncMode = flag;
	}
	
	bool MQueue::Read(P2DBuf* mBuf)
	{
		int status = mq_receive(_mqfd, (char*)mBuf, _bufLen, 0);
		if (status == -1)
			return false;

		return true;
	}


	bool MQueue::Write(const P2DBuf* pBuf)
	{
		if (-1 == mq_getattr(_mqfd, &_mqstat))
			return false;

		if (_mqstat.mq_curmsgs > _maxMqCurmsgs)
			_maxMqCurmsgs = _mqstat.mq_curmsgs;

		if (!_syncMode)
		{
			if (MAXMSG == _mqstat.mq_curmsgs)
			{
				return false;
			}
			else if (MAXMSG < _mqstat.mq_curmsgs + 2)
			{
				switch (_link)
				{
					case LinkType::C2P:
					{
						//TODO
					}break;
					case LinkType::P2D:
					{
						P2DBuf mBuf;
						mBuf.ts = 0;
						mBuf.originID = SERVICE;
						mBuf.devSeverity = CODE_MQ_OVERFLOW;
						mq_send(_mqfd, (char*)&mBuf, _bufLen, 0);
					}break;
				}

				return false;
			}
		}
		
		if (-1 == mq_send(_mqfd, (char*)pBuf, _bufLen, 0))
			return false;

		return true;
	}

	
	void MQueue::Print()
	{
		std::cout << "max: " << _maxMqCurmsgs << " | curr: " << _mqstat.mq_curmsgs << std::endl;
	}
	
	std::string MQueue::GetStat()
	{
		std::stringstream ss;
		ss << "max: " << _maxMqCurmsgs << " | curr: " << _mqstat.mq_curmsgs;
		
		return ss.str();
	}
	
	void MQueue::ResetStat()
	{
		_maxMqCurmsgs = 0;
	}
	
	void DeleteMQ(const LinkType& lt)
	{
		switch (lt)
		{
			case LinkType::C2P:
			{
				mq_unlink(QFileC2P.c_str());
			}break;
			case LinkType::P2D:
			{
				mq_unlink(QFileP2D.c_str());
			}break;
		}
	}

}//namespace