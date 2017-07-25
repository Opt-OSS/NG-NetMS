## LF Only!!! Last empty line required
macro isis_database
  	send show isis database detail

macro ospf_database
  	send show ip ospf database router

macro bgp_database_summary
	send show ip bgp summary

macro bgp_database_neighbors
	send show ip bgp neighbors

macro version
	send show version

macro interfaces
	send show interfaces

macro check_privileged
	send show privilege

#EOF