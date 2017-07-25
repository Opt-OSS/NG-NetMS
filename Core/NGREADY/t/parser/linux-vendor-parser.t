use lib '../lib/';
use strict;
use warnings FATAL => 'all';
#use warnings;
use Emsgd;
use Test::More ; #for syntax only
use Test::MockModule;#for syntax only
use Test::Spec ;
use NGNMS::OLD::Linux;




describe 'linux_parse_model via exec of "cat   /etc/*-rel* /etc/*_ver*" ::::::' => sub {
        ##############################################################################################
        it 'Centos:: CentOS Linux release 7.2.1511 (Core)' => sub {
                my $ret = '
CentOS Linux release 7.2.1511 (Core)
Derived from Red Hat Enterprise Linux 7.2 (Source)
NAME="CentOS Linux"
VERSION="7 (Core)"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="7"
PRETTY_NAME="CentOS Linux 7 (Core)"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:7"
HOME_URL="https://www.centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"

CENTOS_MANTISBT_PROJECT="CentOS-7"
CENTOS_MANTISBT_PROJECT_VERSION="7"
REDHAT_SUPPORT_PRODUCT="centos"
REDHAT_SUPPORT_PRODUCT_VERSION="7"

CentOS Linux release 7.2.1511 (Core)
CentOS Linux release 7.2.1511 (Core)
cpe:/o:centos:centos:7
cat: /etc/*_ver*: No such file or directory
';
                NGNMS::OLD::Linux->expects( 'linux_cmd' )->once()->returns( $ret );
                my $r = NGNMS::OLD::Linux->linux_parse_model();
                is $r, 'CentOS Linux release 7.2.1511 (Core)';
            };
        ##############################################################################################
        it 'Centos:: CentOS release 6.8 (Final)' => sub {
                my $ret = '
CentOS release 6.8 (Final)
LSB_VERSION=base-4.0-ia32:base-4.0-noarch:core-4.0-ia32:core-4.0-noarch:printing-4.0-ia32:printing-4.0-noarch
cat: /etc/lsb-release.d: Is a directory
CentOS release 6.8 (Final)
CentOS release 6.8 (Final)
cpe:/o:centos:linux:6:GA
cat: /etc/*_ver*: No such file or directory';
                NGNMS::OLD::Linux->expects( 'linux_cmd' )->once()->returns( $ret );
                my $r = NGNMS::OLD::Linux->linux_parse_model();
                is $r, 'CentOS release 6.8 (Final)';
            };
        ##############################################################################################
        it 'RedHat:: release 6.7 ' => sub {
                my $ret = '
cat: /etc/*_ver*: No such file or directory
Red Hat Enterprise Linux Server release 6.7 (Santiago)
Red Hat Enterprise Linux Server release 6.7 (Santiago)';
                NGNMS::OLD::Linux->expects( 'linux_cmd' )->once()->returns( $ret );
                my $r = NGNMS::OLD::Linux->linux_parse_model();
                is $r, substr('Red Hat Enterprise Linux Server release 6.7 (Santiago)',0,49);
            };
        ##############################################################################################
        it 'RedHat:: release 6.7 ' => sub {
                my $ret = '
cat: /etc/*_ver*: No such file or directory
Red Hat Enterprise Linux Server release 6.7 (Santiago)
Red Hat Enterprise Linux Server release 6.7 (Santiago)';
                NGNMS::OLD::Linux->expects( 'linux_cmd' )->once()->returns( $ret );
                my $r = NGNMS::OLD::Linux->linux_parse_model();
                is $r, substr('Red Hat Enterprise Linux Server release 6.7 (Santiago)',0,49);
            };
        ##############################################################################################
        it 'Ubuntu:: Ubuntu 14.04.4 LTS ' => sub {
                my $ret = '
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=14.04
DISTRIB_CODENAME=trusty
DISTRIB_DESCRIPTION="Ubuntu 14.04.4 LTS"
NAME="Ubuntu"
VERSION="14.04.4 LTS, Trusty Tahr"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 14.04.4 LTS"
VERSION_ID="14.04"
HOME_URL="http://www.ubuntu.com/"
SUPPORT_URL="http://help.ubuntu.com/"
BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
jessie/sid';
                NGNMS::OLD::Linux->expects( 'linux_cmd' )->once()->returns( $ret );
                my $r = NGNMS::OLD::Linux->linux_parse_model();
                is $r, substr('Ubuntu 14.04.4 LTS',0,49);
            };
    };

describe 'linux_parse_vendor' => sub {
        ########### CENTOS #########################
        #    $ uname -a
        #    Linux web1.offpista.com 2.6.32-504.30.3.el6.i686 #1 SMP Wed Jul 15 10:55:56 UTC 2015 i686 i686 i386 GNU/Linux
        #    $ cat /etc/redhat-release
        #    CentOS release 6.7 (Final)
        it 'Should get vendor Centos' => sub {

                NGNMS::OLD::Linux->expects( 'linux_cmd' )->with( 'uname -s' )->once()->returns( sub {
                        my $cmd = $_[1];
                        if ($cmd eq 'uname -v') {
                            return '#1 SMP Wed Jul 15 10:55:56 UTC 2015 i686 i686 i386 GNU/Linux'
                        } ;
                        if ($cmd eq 'uname -s') {
                            return 'Linux'
                        };
                        if ($cmd eq 'uname -r') {
                            return 'Linux' #'2.6.32-504.30.3.el6.i686'
                        };
                    } );
                my $r = NGNMS::OLD::Linux->linux_parse_vendor();
                is $r, 'Linux';
            };
        it 'Should get vendor ubuntu' => sub {
                NGNMS::OLD::Linux->expects( 'linux_cmd' )->returns( ' Linux ' );
                my $r = NGNMS::OLD::Linux->linux_parse_vendor();
                is $r, 'Linux';
            }
    };
runtests unless caller;