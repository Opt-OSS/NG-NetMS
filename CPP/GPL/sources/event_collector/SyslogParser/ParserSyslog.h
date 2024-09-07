#pragma once

#include <map>
#include <string>

#include "IParser.h"
#include "JunosFacilityGroups.h"

using namespace std;

/* CISCO has following syslog message format

<187> [timestamp in RFC prescribed format] [device dns name | ip address] [Dummy
Value/Counter : ] [ {:|*} mmm dd hh:mm:ss TimeZone ]
%FACILITY-[SUBFACILITY-]SEVERITY-MNEMONIC: description

<187> [timestamp in RFC prescribed format] [device dns name | ip address] [Dummy
Value/Counter : ] [ {:|*} yyyy mmm dd hh:mm:ss TimeZone <-|+> hh:mm]
%FACILITY-[SUBFACILITY-]SEVERITY-MNEMONIC: description
Examples of good syslog messages: [ as sent by the device ]
<187>%PIX-4-106023 description
<187>Mar 23 10:21:03 %PIX-4-106023 description
<187>*Mar 23 12:12:12 PDT %PIX-4-106023 description
<187>Mar 23 10:21:03 *Mar 23 12:12:12 PDT %PIX-4-106023 description
<187>Mar 23 10:21:03 *2003 Mar 23 12:12:12 PDT -8:00 %PIX-4-106023 description
<187>Mar 23 10:21:03 93: *2003 Mar 23 12:12:12 PDT -8:00 %PIX-4-106023 description
*/

/* JunOS has following syslog message format

Structured Format
<14>1 2012-12-20T17:40:07.758-06:00 tok-srx100 RT_FLOW - RT_FLOW_SESSION_CREATE[junos@2636.1.1.1.2.41 reason="unset" source-address="10.140.2.62"
source-port="61718" destination-address="10.199.5.255" destination-port="161" service-name="None" nat-source-address="10.140.2.62" nat-source-port="61718"
nat-destination-address="10.199.5.255" nat-destination-port="161" src-nat-rule-name="None" dst-nat-rule-name="None" protocol-id="17" policy-name="trust_to_trust"
source-zone-name="trust" destination-zone-name="trust" session-id-32="15709" packets-from-client="2" bytes-from-client="143" packets-from-server="0"
bytes-from-server="0" elapsed-time="59" application="UNKNOWN" nested-application="UNKNOWN" username="N/A" roles="N/A" packet-incoming-interface="fe-0/0/5.0"]

Unstructured Format
Jan 28 15:41:28 10.199.4.35 RT_FLOW: RT_FLOW_SESSION_CREATE: session created 10.199.5.107/1->10.199.4.175/44460 icmp
10.199.5.107/1->10.199.4.175/44460 None None 1 default-policy trust dmz 24173 N/A(N/A) fe-0/0/5.0
*/

class CiscoTimestampParser;
class TimestampRFC3164Parser;
class JunosStructuredTimestampParser;
class UnknownTimestampParser;

class ParserSyslog : public IParser
{
public:
	ParserSyslog();
	virtual ~ParserSyslog();
	bool Parse(string Message, bool HasSourceIp, string SourceIP);
	bool ProcessEndOfData();
	void SourceAttached(string IpAddress);
	void SourceDetached(string IpAddress);
	void RegisterListener(ParserListener& Listener);
	void UnregisterListener(ParserListener& Listener);

private:
	bool IsNetscreenFormat(string& Text);
	string Time2String(time_t time);
	string GetTimestamp();
	int GetCurrentYear();
	string GetTimeZone();
	string CreateTimestamp(int Year, int Month, int Day, int Hours, int Minutes, int Seconds);
	string GetTimestamp(JunosStructuredTimestampParser& TimestampParser);
	string GetTimestamp(TimestampRFC3164Parser& TimestampParser);
	string GetTimestamp(UnknownTimestampParser& TimestampParser);
	string GetTimestamp(CiscoTimestampParser& TimestampParser);
	string GetPriority(string Message, string& Priority);
	string GetNumberString(string Text, string& Number);
	string GetString(string Text, string& String);
	string DropWhitespace(string Text);

private:
	Notifier<ParserListener, Event> m_Notifier;
};
