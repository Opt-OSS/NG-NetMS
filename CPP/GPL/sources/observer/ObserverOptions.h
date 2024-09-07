#pragma once

#include <sstream>
#include <string>
#include <vector>

using std::ostream;
using std::string;

class ObserverOptions
{
public:
	ObserverOptions();
	bool Parse(int argc, char* argv[]);
	string GetDbSettingsFileName();
	string GetLogFileName();
	string GetConfigFileName();
	int GetVerbose();
	bool GetMDef();
	bool GetDrop();
	bool GetUpdate();
	int GetMaxInterval();

private:
	string m_LogFileName;
	string m_ConfigFileName;
	string m_DbSettingsFileName;
	int m_Verbose;
	bool m_MDef;
	bool m_Drop;
	bool m_Update;
	int m_MaxInterval;

	void ShowUsage(ostream& Stream);
};
