#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <cstring>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include "Triggers.h"

void Triggers::Execute(  const string& ActionScript, const Event& event  )
{
    int pid = vfork();
    if( !pid )
    {
	char sev[12];
	sprintf( sev, "%d", event.getSeverity() );
        const char *tmp[] =
        {
            ActionScript.c_str(),
	    sev,
	    event.getPriority().c_str( ),
	    event.getTs().c_str( ),
	    event.getOrigin().c_str( ),
	    event.getFacility().c_str( ),
	    event.getCode().c_str( ),
	    event.getDescr().c_str( ),
	    0
        };

        execvp( tmp[0], (char**)tmp );
        _exit(1);
    }

    int chStat;
    wait4( 0, &chStat, WNOHANG, 0); // check if any spawned children had terminated
}
