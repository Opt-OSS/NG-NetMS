#Poll-Host Interface getInterfaces Method

##getInterfaces:
```perl
	 	my($physical_int, $logical_interfaces) = moduleInstance->parse_interfaces()
```

- *returns* list of hash refs ($physical_int, $logical_interfaces)



where should be as
```perl
$physical_int =	{
		'eth0'=>{                                    #name of physical interface,
			'state' 		=> 'enabled',            #admin status 'enabled'|'disabled'
			'speed' 		=> '10000Mb/s',          # 10000Mb/s| 1000  .....
			'condition' 	=>  'up',                #physical link state 'up'|'down'|'unknown',
			'description' 	=> '01:02:03::04:05:06', #description|mac(Linux)
		},
		   ...
};
```
```perl
$logical_interfaces = {
		'eth0:1'=>{                                         #name of logical interface
			'physical_interface_name' => 'eth0',            #name of the physical interface this interface is attahed to
			'ip' 			          => '192.168.0.1',     #ip daress
			'mask' 			          => '255.255.255.0',   #network mask in  255.255.255.255 form
			'description'			  => 'enabled',         #description|Admin state for linux
	   	},
	  		   ...

};
```
####logical interfaces name convention:
if logical interface has more than one IP it should be split
into the multiple logical interfaces (separate interface for each IP).
Such interface (with )more than one IP) should be named like this:
 ```
'logical_interface_name:0' for first IP
'logical_interface_name:1' for second IP
...
'logical_interface_name:N' for Ns IP
```
`'physical_interface_name'`  and `'descr'` should be the same as  in base interface

for ex. linux inerface eth1:0 could have 2 IP's (this weird,
but you could set one secondary IP for _eth0_ with `ifconfig`,
this will slit _eth0_ into _eth0:0_ and _eth0:1_, than `ip address add 10.0.0.0/24 dev eth0:1`
and _eth0:1_ will have 2 IPs)
So _eth0:1_ should be splited to _eth0:1:0_  and _eth0:1:1_ . That is.
###Linux
inetrfaces listed via `ip address show` cause `ifconfig` marked as obsolete.
Linux module target only generic Linux hosts.
Special devices with Linux as OS should be parsed as separate devices

	for now we dont parse separate output of `ip link show` to get list
	of physical interfaces . Its  outout differ from `ip address show` mostly for hypervisors (Citrx etc)
	and for now we don't officially support any of hypervisors engines.
	
##Saving to DB
###Physical interfaces
- Interface identified by its `name` in router scope.
That is. (`router_id`,`name`) should be unique in `phy_int` table
- Physical interface updated if it already exists,
otherwise  new interface for router should be created in DB.
- Physical interface should be deleted for router if no interface had been  found
due latest interface parse process
###Logical interface
- Interface identified by its (`ph_int_id`,`name`,`ip_addr`) in router scope.
That is. (`router_id`,`ph_int_id`,`name`,`ip_addr`) should be unique in `phy_int` table
- Logical  interface updated if it already exists,
otherwise  new interface for router should be created in DB.
- Logical interface should be deleted for router if no interface  had been found
due latest interface parse process



	