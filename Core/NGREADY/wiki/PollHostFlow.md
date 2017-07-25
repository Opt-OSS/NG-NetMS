#Poll Host process flow

All hosts in routers table will be connected with poll-host process.
Hosts could be added to table via discovery or network scan processes.
each host should have access method assigned to or resopnd to defauld access method.
After host initially added to table its host name the same as IP
__If host added via audit (for ex. IS-IS protocol) it could not have IP__



main flow:

### 0. Pre-check

Search  DB for host with **IP or hostname** matched `--host` command line option.
If host not found, stop processing.
Get connection credentials for host by priority:

 1. command line options
 2. host specific access method from DB
 3. Default credentials 
 
credentials are:

 - transport Telnet| SSHv1| SSHv2 etc
 - user name
 - password
 - privileged password 
 - SNMP community
 
### 0.1 Host IP obtaining
- get IP by resolve DNS
- If ip is changed, save new IP to DB.
- if no result from DNS, use IP from DB

__On further processing Use IP obtained on this stage__ 
 
### 1. Resolve host type
	
1. from command line option (--host-type)
 
3. else: SNMP query of OID `1.3.6.1.2.1.1.2.0` (SysObject.0) by host IP
4. else: Host type form router table 

if host type is not resolved, host processing stops  

### 2. Plugin selection  (stops on first success)
- if host type resolved via command line option (--host-type) , call `checkDeviceSupported ` 
for all available plugins until first success  
- if host type resolved via SNMP,   call  `checkSNMPsysObjectID ` 
for all available plugins until first success    

**First** plugin responded with `true` selected for the host processing. 

### 3. Connection establishing
call `getPersonality`,`getPhraseBook`,`getRequiresPrivileged`.
try connect to host by  `--host` address. if fails and it is hostname try IP, if it is IP try hostname
  
and try to establish connection to host (Net::Appliance::Session)

if success inject session into plugin, _mark host as UP 
and start HostName resolving

### Host Name Resolving
after successfull connection to host 

### 4. Main process 
```perl
return unless $plugin_module->beforeProcessing();
$plugin_module->getModel();
$plugin_module->getVendor();
$plugin_module->getHardware();
$plugin_module->getSoftware();
$plugin_module->getLocation();
$plugin_module->getInterfaces();
$plugin_module->getIpLayer();
```