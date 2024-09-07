#include "ObserverOptions.h"

#include <getopt.h>

#include <iostream>
#include <string>

using std::cerr;
using std::endl;
using std::string;

ObserverOptions::ObserverOptions():
	m_LogFileName("ngnms_observer.log"), m_ConfigFileName("options.json"), m_DbSettingsFileName("db.cfg"), m_Verbose(1),
	m_MaxInterval(300), m_MDef(false), m_Drop(false)
{
}

bool ObserverOptions::Parse(int argc, char* argv[])
{
	int next_option;
	/*
	 * form optstring
	 * a	- no value
	 * a:	- has value
	 * a::	- optional value
	 */
	const std::string short_options = "hi:o:l:c:mDUv:i:";
	struct option long_options[] = {
		{"help", 0, NULL, 'h'},
		{"options", 1, NULL, 'o'},
		{"log", 1, NULL, 'l'},
		{"config", 1, NULL, 'c'},
		{"mdef", 0, NULL, 'm'},
		{"drop", 0, NULL, 'D'},
		{"update", 0, NULL, 'U'},
		{"verbose", 1, NULL, 'v'},
		{"imax", 1, NULL, 'i'},
		{NULL, 0, NULL, 0}};

	do
	{
		next_option = getopt_long(argc, (char**)argv, short_options.c_str(), long_options, NULL);
		switch (next_option)
		{
		case 'h':
			ShowUsage(cerr);
			return false;
		case 'o':
			m_DbSettingsFileName = optarg;
			break;
		case 'l':
			m_LogFileName = optarg;
			break;
		case 'c':
			m_ConfigFileName = optarg;
			break;
		case 'v':
			m_Verbose = atoi(optarg);
			if (m_Verbose < 1 || m_Verbose > 3)
			{
				ShowUsage(cerr);
				return false;
			}
			break;
		case 'i':
			m_MaxInterval = atoi(optarg);
			if (m_Verbose < 1)
			{
				ShowUsage(cerr);
				return false;
			}
			break;
		case 'm':
			m_MDef = true;
			break;
		case 'D':
			m_Drop = true;
			break;
		case 'U':
			m_Update = true;
			break;
		case '?':
			ShowUsage(cerr);
			return false;
		case -1:
			break;
		default:
			return true;
		}
	} while (-1 != next_option);

	return true;
}

string ObserverOptions::GetDbSettingsFileName()
{
	return m_DbSettingsFileName;
}

string ObserverOptions::GetLogFileName()
{
	return m_LogFileName;
}
string ObserverOptions::GetConfigFileName()
{
	return m_ConfigFileName;
}

int ObserverOptions::GetVerbose()
{
	return m_Verbose;
}

bool ObserverOptions::GetMDef()
{
	return m_MDef;
}

bool ObserverOptions::GetDrop()
{
	return m_Drop;
}

bool ObserverOptions::GetUpdate()
{
	return m_Update;
}

int ObserverOptions::GetMaxInterval()
{
	return m_MaxInterval;
}

void ObserverOptions::ShowUsage(ostream& Stream)
{
	Stream << "Usage:" << endl;
	Stream << " [-o|--options] <filename> Configuration file with encrypted data base options. Default is ./db.cfg" << endl;
	Stream << " [-l|--log] <filename>     Log file location. Default is ./ngnms_observer.log" << endl;
	Stream << " [-c|--config] <filename>  Configuration file location. Default is ./options.json" << endl;
	Stream << " [-m|--mdef]               Set options monitorable by default" << endl;
	Stream << " [-U|--update              Update Observer database tables" << endl;
	Stream << " [-D|--drop]               Create/renew Observer database tables" << endl;
	Stream << " [-v|--verbose]            Verbose message level" << endl;
	Stream << " [-i|--imax]               Max request interval in seconds. Default is 300s" << endl;
	Stream << " [-h|--help]               This help screen" << endl;
}
