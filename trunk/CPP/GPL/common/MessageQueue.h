#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/wait.h>
#include <mqueue.h>
#include <string>

//service message
const int SERVICE = 0;
//service code
const int CODE_TS_END = 0;
const int CODE_MQ_OVERFLOW = 1;

typedef struct
{
    time_t  ts;
    int     originID;
    int     devSeverity;
} P2DBuf;

class MQueue
{
    public:
        MQueue(  );
        ~MQueue( );
        bool Read( P2DBuf* mBuf );
        bool Write( const P2DBuf* pBuf );
        bool IsOpen( );
        void SetSyncMode( bool flag );
        void ResetStat();
        int GetPendingMessages( );

        // TOTO delete this both methods!
        std::string GetStat();
        void Print();

    private:
        mqd_t		m_fd;
        bool		_syncMode;
        int	        _maxMqCurmsgs;
};

