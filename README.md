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

IMPORTANT: Before proceeding, ensure that you have root permissions and administrative rights for the network about to be discovered or managed.
If in doubt, consult with your network administrator or company management.
Do not try to discover and manage networks for which you do not have administrative rights. This may result in your IP address being banned or even serious legal consequences.

## POSTGRESQL INSTALL
As root install PSQL

### Centos
Which version of PGSQL you get by default will depend on the version of the distribution.
You may use PostgreSQL Yum Repository, if the version supplied by your operating system is not the one you want.
The PostgreSQL Yum repository currently supports many Linux and Unix distributions.

In order to use the PostgreSQL Yum Repository repository, you must first install the repository RPM. 
For example download the 9.5 RPM from the repository RPM listing, and install it with commands:

`yum install postgresql95-server postgresql95-contrib`
`sudo /usr/pgsql-9.5/bin/postgresql95-setup initdb`

Enable PostgerSQL 9.5 and start:

`sudo systemctl list-unit-files | grep postgresql`
`sudo systemctl enable postgresql-9.5.service`
`sudo systemctl start postgresql-9.5.service`

Check your work:

`service postgresql-9.5 status`

`psql --version`


### Ubuntu
Quickest way to get PGSQL is to use apt-get utility.

`sudo apt-get update`
`sudo apt-get install postgresql postgresql-contrib`

In order to install and configure a cluster of PGSQL servers, follow the original documentation on http://postgresql.org

To start, stop or restart PGSQL use the /etc/init.d/postgresql script:

`# /etc/init.d/postgresql start`
`user@host:/etc/init.d$ sudo ./postgresql start`

Verify PGSQL operation with:

`postgresql status`

## CREATE USER ngnms

```bash
useradd -m ngnms -s /bin/sh
usermod ngnms -G wheel
```

switch to ngnms user

```bash
su -l ngnms 
check if you ngnms user can do sudo commands
sudo -l
```

### Centos
```bash
[ngnms@localhost]$ sudo yum install epel-release  deltarpm
[ngnms@localhost]$ sudo yum install git cmake make gcc-c++ perl cpanminus nmap pcre-devel libpqxx-devel flex flex-devel net-snmp-devel cryptopp-devel boost-devel postgresql-devel telnet libmcrypt
[ngnms@localhost]$ sudo cpanm install --no-man-pages --notest Dist::Zilla::Plugin::PodWeaver  Pod::Weaver::Section::GenerateSection 
[ngnms@localhost]$ git clone https://github.com/opt-oss/NG-NetMS.git
[ngnms@localhost]$ cp NG-NetMS/settings.cmake.dist NG-NetMS/settings.cmake
[ngnms@localhost]$ vi NG-NetMS/settings.cmake
[ngnms@localhost]$ mkdir build
[ngnms@localhost]$ cd ./build
[ngnms@localhost]$ cmake ../NG-NetMS
[ngnms@localhost]$ make
[ngnms@localhost]$ sudo mkdir -p /opt/ngnms
[ngnms@localhost]$ sudo chown ngnms /opt/ngnms
[ngnms@localhost]$ make install
```

### Ubuntu
```bash
[ngnms@localhost]# sudo apt-get update
[ngnms@localhost]$ sudo apt-get install git cmake make gcc-c++ perl cpanminus nmap pcre-devel libpqxx-devel flex flex-devel net-snmp-devel cryptopp-devel boost-devel postgresql-devel telnet libmcrypt
[ngnms@localhost]$ sudo cpanm install --no-man-pages --notest Dist::Zilla::Plugin::PodWeaver  Pod::Weaver::Section::GenerateSection
[ngnms@localhost]$ git clone https://github.com/opt-oss/NG-NetMS.git
[ngnms@localhost]$ cp NG-NetMS/settings.cmake.dist NG-NetMS/settings.cmake
[ngnms@localhost]$ vi NG-NetMS/settings.cmake
[ngnms@localhost]$ mkdir build
[ngnms@localhost]$ cd ./build
[ngnms@localhost]$ cmake ../NG-NetMS
[ngnms@localhost]$ make
[ngnms@localhost]$ sudo mkdir -p /opt/ngnms
[ngnms@localhost]$ sudo chown ngnms /opt/ngnms
[ngnms@localhost]$ make install
```

### Perl deps

If the ngnms is not installed in /opt/ngnms do this in build directory
```shell
[ngnms@localhost build]$ sudo make perl-install-deps
```
and then install with make install

or (in install dir)
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
### Enviroment
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

## Setup Web-Server
### HTTPD for default directory config
use `su` account for operations below

#### SELinux
SELinux prevents symlink references from working if enforced. We use simlinks to simplify installation and operations.

__warning__
[Disable SELinux](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Security-Enhanced_Linux/sect-Security-Enhanced_Linux-Enabling_and_Disabling_SELinux-Disabling_SELinux.html)

Edit vi /etc/selinux/config
and change the following line to permissive or disabled.
```shell
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=permissive
```

Then execute: 

`setenforce 0`

to check enforcing status. 

If disabling SELinux enforcement is not an option, just copy the /opt/ngnms/www to /var/www and set permissions for ngmns and your apache users accordingly manually.

```
[ngnms@localhost build]$ sudo yum install httpd php php-pdo_pgsql php-pgsql php-pear php-mcrypt
[ngnms@localhost build]$ sudo pear install Net_IPv4
[ngnms@localhost build]$ sudo systemctl enable httpd.service

__For new install remove /var/www/html __
`this will remove all previously installed default server content`

[ngnms@localhost build]$ sudo ln -s /opt/ngnms/www/html /var/www/html
[ngnms@localhost build]$ cp /opt/ngnms/www/custom_config/main.php.example /opt/ngnms/www/custom_config/main.php
[ngnms@localhost build]$ sudo chown -R ngnms:apache /opt/ngnms/www
```

### PHP

short_open_tag should be ennabled.

This can be done by enabling short_open_tag in php.ini:

short_open_tag = on


If you do not have access to the php.ini you can try to enable short_open_tag trough the .htaccess file.

php_value short_open_tag 1

NOTE: it's possible that host admin disabled the second option. Verify your permissions with your system administrators.


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

# Centos
[ngnms@localhost build]$ sudo systemctl enable ngnms-audit
[ngnms@localhost build]$ sudo systemctl start ngnms-audit
[ngnms@localhost build]$ sudo systemctl status ngnms-audit 
```
# Ubuntu
copy provided jm-worker-initd.sh file into /etc/init.d while renaming it to jm-worker-initd
then do:
```
update-rc.d jm-worker-initd defaults
update-rc.d jm-worker-initd enable
```

This should create all symlinks in /etc/rcX.d directories.
[TODO] Add a respawn line for this service at the bottom of the /etc/inittab file


### nmap sudo

```shell
[ngnms@localhost ~]$ sudo cp /opt/ngnms/nmap.sudo /etc/sudoers.d/nmap
```

### collector

```shell
[ngnms@localhost bin]$ cd /opt/ngnms/bin
[ngnms@localhost bin]$ ./ngnetms_db      
[ngnms@localhost bin]$ sudo -E ${NGNMS_HOME}/bin/ngnetms_collector -s syslog-udp -p 514 -c ${NGNMS_HOME}/bin/db.cfg -r ${NGNMS_HOME}/rules/rules.txt -l ${NGNMS_LOGS}/syslog_collector.log -v &  
```
