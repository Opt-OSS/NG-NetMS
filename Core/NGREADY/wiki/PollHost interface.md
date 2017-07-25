#Interface for PollHost modules
Class should inherit from the NGNMS::Net::PollHost
new instance of Module Class created only  if `ModuleName::checkSNMPsysObjectID($string)==1`


- Module should not write to $DB or avoid to invoke $DB methods that writes to $DB
- Module should not connect to device by itself and must not connect to other devices
- Module should execute commands on device by calling `$session->cmd` function
- Creating module as Singleton pattern should be avoided.

New instance of module created by calling ModuleName->new method with parameters:
- $db - instance of the  NGNMS::DB (connection to database opened)
- $session - Instance of NGNMS::Connect, connected to host
- $host_ip - ip address of host

##Class should implement all of the following methods :
### *Connection establishing stage*
####checkSNMPsysObjectID($response)
- `$response` is a string received from IP for sysObjectID.0 SNMP request.
Returns 1 if device is supported by this module, 0 otherwise

```perl
	sub checkSNMPsysObjectID($response) {
	# Module that supports Juniper
 	return 1 if  $response =~ /1\.3\.6\.1\.4\.1\.2636\..*/;
	# Module that supports Cisco
	return 1 if  $response =~ /1\.3\.6\.1\.4\.1\.9\..*/ ;
	return 0;
}
```
####checkDeviceSupported($host_type)
return 1 | 0
in case pollhost process for the device runs with manual device vendor (--host-type option) 
in command line option, SMNP check will not be performed.
Value of command line option passed as parameter host_type to this function
Returns 1 if device is supported by this module

#### getPersonality
should return personality for Net::Appliance::Session session.
see exapmles at `/usr/local/share/perl/5.18.2/Net/CLI/Interact/phrasebook/`
**required value**

#### getPhraseBook
include Phrasebook for for Net::Appliance::Session session.
**could be undef**

#### getRequiresPrivileged
return 1 if host requires priveleged mode (like enable for Cisco)

### *Processing stage*

#### beforeProcessing
called after connection to the host established
if returns 0 no further processing will be performed
if returns true all functions below will be called
```
	use this function to prepare required shared data for further processng 
```
####getIpLayer
returns integer with device OSI model layer (5 for Linux)  **required value**

####getVendor
returns string representing HW vendor, for ex `'Cisco'`,`'Linux'`,`'Juniper'` **required value**

####getModel
returns string with device model (release for Linux), for ex `'ciscoMC3810'`, `'Ubuntu 14.04.2 LTS'` **required value**

####getInterfaces
_See InterfaceParser page_

####getLocation
string with location of device, could be empty string

####getHardware
returns array of hash, each item represents single hardware item, such as motherboard, CPU, memory
```perl
	@hw_info = [
		{
			hw_item 	=> 'Memory',             #Hardware type, such as Memory, processor
         	hw_name     => 'RAM',                #Hardware short description? such as RAM,NVRAM, CPU x86
			hw_ver      => 'N/A',                 #Some ident string, such as Serial number , revision
			hw_amount   =>  '14336K/2048K bytes', #meaningful value of hardware (number of CPU, memory amount etc)
		},
		# ....
	];

```
This array saved to DB and used in Devices->HW inventory report and
_could be empty_, array length not limited
####getSoftware
returns array of hashes, each array item represents platform software, such as bootloader version, BIOS or firmware versions, OS version etc
```perl
	@swinfo = [
		{
			sw_item	=> 'Operating system', #type of software (Operating system, Firmware, Software)
			sw_name=>  'IOS (tm) MC3810 Software (MC3810-I5K9S-M)',
			sw_ver => '12.2(29b)'
		},
		{
			sw_item	=> 'Firmware', #type of software (Operating system, Firmware, Software)
			sw_name=>  'ROM: System Bootstrap',
			sw_ver => '11.3(1)MA1'
		}
				# ....
	]
```
This array saved to DB and used in Devices->SW inventory report and
_could be empty_, array length not limited


####getNetworks
returns array of hash of IP addresses and mask for all networks device has interface attached
```perl
 @IPs = [
 	{ ip=>'10.0.1.1' , mask=> '255.255.255.0' }
 	{ ip=>'10.0.4.5' , mask=> '/24' }
 ]
 Ususally thsi is the simple subset of logical interfaces IP/mask
```
There is no need to convert interface IP to network address, this would be done automatically.
Also netmask could be in any  format. Conversation will be made wthi [Nett:Netmask](https://metacpan.org/pod/distribution/Net-Netmask/lib/Net/Netmask.pod) module

####getConfig
returns text (multiline string) that will be saved as device config. Could be empty;
####getModuleName
Plugin module name for debug log
```perl
sub getModuleName{
    return __PACKAGE__;
}
```