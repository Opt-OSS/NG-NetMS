# NG-NetMS

Why to pay tens of thousands $$$ for your network management software?

Get visibility into your networks and complex processes inside with NG-NetMS now!

NG-NetMS is a new end-to-end network management platform for your Linux servers, Cisco, Juniper, HP and Extreme routers, switches and firewalls.

NG-NetMS is precise, quick and efficient. It collects most complete information about the network inventory, topology, map of IPv4 addresses quickly and with minimum hassle. 
Most important you will be able to collect, process and analyse Syslog events and SNMP alarms both in near-real-time and from the historical archives in a new way.

We successfully used NG-NetMS for delivery of network assessment services for our customers worldwide for many years. And now we want to share this unique and fully functional tool with community. It is not capped in terms of performance or number of nodes. The only limit is the hardware you deploy it on.

http://www.opt-net.eu/products

License
Apache License V2.0, GNU General Public License version 3.0 (GPLv3), GNU Library or Lesser General Public License version 3.0 (LGPLv3)


## Installing

```bash
[ngnms@localhost build]$ sudo yum install epel-release  deltarpm
[ngnms@localhost build]$ sudo yum install cmake make gcc-c++ perl cpanminus nmap pcre-devel libpqxx-devel flex flex-devel net-snmp-devel cryptopp-devel boost-devel postgresql-devel telnet libmcrypt
[ngnms@localhost build]$ sudo cpanm install --no-man-pages --notest Dist::Zilla::Plugin::PodWeaver  Pod::Weaver::Section::GenerateSection 
[ngnms@localhost build]$ git clone https://github.com/opt-oss/NG-NetMS.git
[ngnms@localhost build]$ mkdir ./build
[ngnms@localhost build]$ cd ./build
[ngnms@localhost build]$ cp ../ngnms-open-source/settings.cmake.dist ../ngnms-open-source/settings.cmake
[ngnms@localhost build]$ vi ../ngnms-open-source/settings.cmake
[ngnms@localhost build]$ cmake ../ngnms-open-source
[ngnms@localhost build]$ make
[ngnms@localhost build]$ sudo mkdir -p /opt/ngnms
[ngnms@localhost build]$ sudo chown ngnms /opt/ngnms
[ngnms@localhost build]$ make install
```


### Perl deps

either 
```shell
[ngnms@localhost build]$ sudo make perl-install-deps
```
or
```shell
ngnms@localhost ngnms]$ pwd
/opt/ngnms
[ngnms@localhost ngnms]$ sudo cpanm --no-man-pages --notest --installdeps .
[sudo] password for ngnms:
--> Working on .
Configuring /opt/ngnms ... OK
```

## After-install Configuring
### Database
 perform usual steps to setup postgres and start service
 `sudo systemctl start postgresql-9.5`
```shell
[ngnms@localhost build]$ sudo su -l postgres                
Last login: Tue Jun 27 12:00:28 CEST 2017 on pts/1         
-bash-4.2$ createuser -d --pwprompt ngnms                  
Enter password for new role:                               
Enter it again:                                            
-bash-4.2$                                                 
```
## Enviroment
```
 sudo su
 [root@localhost database]# cat /opt/ngnms/env.list >> /etc/environment
```
logout and login

### DBinit

```shell
[ngnms@localhost build]$ cd /opt/ngnms/database/
[ngnms@localhost database]$ ./db_init.sh -r init-db.sql
[ngnms@localhost database]$ ./migrate.pl  --upgrade=latest
```


### HTTPD for default directory config
use `su` account for operations below
####SELinux
setting up of `selinux` permission is out iof this document scope

__dangerous__
[Disable SELinux](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Security-Enhanced_Linux/sect-Security-Enhanced_Linux-Enabling_and_Disabling_SELinux-Disabling_SELinux.html)

`setenforce 0`

__remove /var/www/html if exists__
`this will remove all previously installed default server content`

```
[ngnms@localhost build]$ sudo yum install httpd php php-pdo_pgsql php-pgsql php-pear php-mcrypt
[ngnms@localhost build]$ sudo pear install Net_IPv4
[ngnms@localhost build]$ sudo systemctl enable httpd.service
[ngnms@localhost build]$ sudo ln -s /opt/ngnms/www/html /var/www/html
[ngnms@localhost build]$ cp /opt/ngnms/www/custom_config/main.php.example /opt/ngnms/www/custom_config/main.php
[ngnms@localhost build]$ sudo chown -R ngnms:apache /opt/ngnms/www
```

## Services

### Cron 
as user `ngnms`
```shell
[ngnms@localhost ~]$ crontab /opt/ngnms/crontab.init
```
wait 5 minutes for scheduled tasks added and script created

### Audit worker
```shell
[ngnms@localhost build]$ sudo cp /opt/ngnms/ngnms-audit.service /etc/systemd/system/ngnms-audit.service
[ngnms@localhost build]$ sudo systemctl enable ngnms-audit
[ngnms@localhost build]$ sudo systemctl start ngnms-audit
[ngnms@localhost build]$ sudo systemctl status ngnms-audit 
```
#### namp sudo
```shell
[ngnms@localhost ~]$ sudo cp /opt/ngnms/nmap.sudo /etc/sudoers.d/nmap
```

###collector
```shell
[ngnms@localhost bin]$ cd /opt/ngnms/bin
[ngnms@localhost bin]$ ./ngnetms_db      
[ngnms@localhost bin]$ sudo -E ${NGNMS_HOME}/bin/ngnetms_collector -s syslog-udp -p 514 -c ${NGNMS_HOME}/bin/db.cfg -r ${NGNMS_HOME}/rules/rules.txt -l ${NGNMS_LOGS}/syslog_collector.log -v &  
```
