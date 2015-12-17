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

using namespace std;

#define PMODE   0655
#define MAXMSG  1000

using std::string;
const string QFileP2D = "/p2d";

MQueue::MQueue( ) :
_syncMode(false),
_maxMqCurmsgs(0)
{
    struct mq_attr attr;
    attr.mq_maxmsg = MAXMSG;
    attr.mq_msgsize = sizeof( P2DBuf );

    m_fd = mq_open( QFileP2D.c_str(), O_RDWR | O_CREAT, PMODE, &attr );

    if( IsOpen() )
    {
        int count = GetPendingMessages( );
        for( int i = 0; i < count; ++i )
        {
            P2DBuf dummyBuffer;
            Read( &dummyBuffer );
        }
    }
}

bool MQueue::IsOpen()
{
    return ( m_fd != -1 );
}

MQueue::~MQueue()
{
    mq_close( m_fd );
}

void MQueue::SetSyncMode(bool flag)
{
    _syncMode = flag;
}

bool MQueue::Read(P2DBuf* mBuf)
{
    timespec timeout;
    timeout.tv_sec = 0;
    timeout.tv_nsec = 1000;
    return ( -1 != mq_timedreceive( m_fd, (char*) mBuf, sizeof( P2DBuf ), 0, &timeout ) );
}

int MQueue::GetPendingMessages( )
{
    mq_attr  mqstat;
    return ( -1 != mq_getattr( m_fd, &mqstat ) ) ? mqstat.mq_curmsgs : 0;
}

bool MQueue::Write(const P2DBuf* pBuf)
{
    int messageCount = GetPendingMessages( );
    _maxMqCurmsgs  = max( GetPendingMessages( ), _maxMqCurmsgs );

    if ( !_syncMode )
    {
            if (MAXMSG == messageCount )
            {
                    return false;
            }
            else if ( MAXMSG < messageCount + 2 )
            {
                P2DBuf mBuf;
                mBuf.ts = 0;
                mBuf.originID = SERVICE;
                mBuf.devSeverity = CODE_MQ_OVERFLOW;
                mq_send(m_fd, (char*)&mBuf, sizeof( P2DBuf ), 0);
                return false;
            }
    }

    return ( -1 != mq_send( m_fd, (char*)pBuf, sizeof( P2DBuf ), 0 ) );
}

void MQueue::Print()
{
    std::cout << "max: " << _maxMqCurmsgs << " | curr: " << GetPendingMessages( ) << std::endl;
}

std::string MQueue::GetStat()
{
    std::stringstream ss;
    ss << "max: " << _maxMqCurmsgs << " | curr: " <<  GetPendingMessages( );
    return ss.str();
}

void MQueue::ResetStat()
{
    _maxMqCurmsgs = 0;
}
