use lib '../lib/';
use strict;
use warnings FATAL => 'all';
#use warnings;
use Emsgd;
use Test::More ; #for syntax only
use Test::MockModule;#for syntax only
use Test::Spec ;
use NGNMS::OLD::Linux;

sub a{
    return  undef;
}
my $comname = undef;
diag $comname || 'new name';
die;
#Ubuntu 14.04.4 LTS  VAR1
my $u1404_1 =
'
eth0      Link encap:Ethernet  HWaddr 00:0c:29:7d:ac:46
          inet addr:192.168.3.117  Bcast:192.168.3.255  Mask:255.255.255.0
          inet6 addr: fe80::20c:29ff:fe7d:ac46/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:12478149 errors:0 dropped:743 overruns:0 frame:0
          TX packets:14414634 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:2011985763 (2.0 GB)  TX bytes:1107189751 (1.1 GB)

eth1      Link encap:Ethernet  HWaddr 00:0c:29:7d:ac:50
          inet6 addr: fe80::20c:29ff:fe7d:ac50/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:2411905 errors:0 dropped:33 overruns:0 frame:0
          TX packets:24 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:144714300 (144.7 MB)  TX bytes:1944 (1.9 KB)

eth1.10   Link encap:Ethernet  HWaddr 00:0c:29:7d:ac:50
          inet addr:172.17.133.11  Bcast:172.17.133.255  Mask:255.255.255.0
          inet6 addr: fe80::20c:29ff:fe7d:ac50/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)

eth1.20   Link encap:Ethernet  HWaddr 00:0c:29:7d:ac:50
          inet addr:172.17.20.11  Bcast:172.17.20.255  Mask:255.255.255.0
          inet6 addr: fe80::20c:29ff:fe7d:ac50/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)

eth1.20:0 Link encap:Ethernet  HWaddr 00:0c:29:7d:ac:50
          inet addr:172.17.20.12  Bcast:172.17.20.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:293943136 errors:0 dropped:0 overruns:0 frame:0
          TX packets:293943136 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:32491569814 (32.4 GB)  TX bytes:32491569814 (32.4 GB)

';
#Ubuntu 14.04.4 LTS    VAR2
my $u1404_2='
eth0      Link encap:Ethernet  HWaddr 00:50:56:2c:56:e2
          inet addr:129.192.44.21  Bcast:129.192.44.63  Mask:255.255.255.192
          inet6 addr: fe80::250:56ff:fe2c:56e2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:171395 errors:0 dropped:40 overruns:0 frame:0
          TX packets:106959 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:19530297 (19.5 MB)  TX bytes:23168187 (23.1 MB)

eth1      Link encap:Ethernet  HWaddr 00:50:56:20:d8:b9
          inet addr:10.10.100.21  Bcast:10.10.100.255  Mask:255.255.255.0
          inet6 addr: fe80::250:56ff:fe20:d8b9/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:22898 errors:0 dropped:1185 overruns:0 frame:0
          TX packets:6038 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:2488810 (2.4 MB)  TX bytes:681436 (681.4 KB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:7415258 errors:0 dropped:0 overruns:0 frame:0
          TX packets:7415258 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:691564810 (691.5 MB)  TX bytes:691564810 (691.5 MB)

test_vlan_41 Link encap:Ethernet  HWaddr 00:50:56:20:d8:b9
          inet addr:192.168.1.21  Bcast:192.168.1.255  Mask:255.255.255.0
          inet6 addr: fe80::250:56ff:fe20:d8b9/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:13190 errors:0 dropped:0 overruns:0 frame:0
          TX packets:3599 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:929656 (929.6 KB)  TX bytes:444791 (444.7 KB)
';

## Red Hat Enterprise Linux Server release 7.2 (Maipo)
my $rh7 = '
ens192: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.3.121  netmask 255.255.255.0  broadcast 192.168.3.255
        inet6 fe80::20c:29ff:fe32:76f8  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:32:76:f8  txqueuelen 1000  (Ethernet)
        RX packets 4300  bytes 275123 (268.6 KiB)
        RX errors 0  dropped 2  overruns 0  frame 0
        TX packets 253  bytes 26983 (26.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ens224: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet6 fe80::20c:29ff:fe32:7602  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:32:76:02  txqueuelen 1000  (Ethernet)
        RX packets 1798  bytes 107880 (105.3 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 35  bytes 4541 (4.4 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ens224.10: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.17.133.129  netmask 255.255.255.0  broadcast 172.17.133.255
        inet6 fe80::20c:29ff:fe32:7602  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:32:76:02  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 27  bytes 3893 (3.8 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 0  (Local Loopback)
        RX packets 4  bytes 340 (340.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 4  bytes 340 (340.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

virbr0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 192.168.122.1  netmask 255.255.255.0  broadcast 192.168.122.255
        ether 52:54:00:cf:e8:6f  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

virbr0-nic: flags=4098<BROADCAST,MULTICAST>  mtu 1500
        ether 52:54:00:cf:e8:6f  txqueuelen 500  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

';
# REdHat 67
my $RH2 = '
eth0      Link encap:Ethernet  HWaddr 00:50:56:02:01:00
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:29487 errors:0 dropped:0 overruns:0 frame:0
          TX packets:46 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:10000
          RX bytes:1940875 (1.8 MiB)  TX bytes:3812 (3.7 KiB)

eth0.50   Link encap:Ethernet  HWaddr 00:50:56:02:01:00
          inet addr:129.192.44.219  Bcast:129.192.44.255  Mask:255.255.255.192
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:28474 errors:0 dropped:0 overruns:0 frame:0
          TX packets:46 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1341537 (1.2 MiB)  TX bytes:3812 (3.7 KiB)

eth1      Link encap:Ethernet  HWaddr 00:50:56:02:01:01
          inet addr:10.10.100.27  Bcast:10.10.100.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:202184 errors:0 dropped:0 overruns:0 frame:0
          TX packets:136901 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:35259458 (33.6 MiB)  TX bytes:49535684 (47.2 MiB)

eth1.10   Link encap:Ethernet  HWaddr 00:50:56:02:01:01
          inet addr:129.192.44.91  Bcast:129.192.44.127  Mask:255.255.255.192
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:18330 errors:0 dropped:0 overruns:0 frame:0
          TX packets:33 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:843180 (823.4 KiB)  TX bytes:1386 (1.3 KiB)

eth1.411  Link encap:Ethernet  HWaddr 00:50:56:02:01:01
          inet addr:192.168.11.27  Bcast:192.168.11.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:40898 errors:0 dropped:0 overruns:0 frame:0
          TX packets:7280 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:3059267 (2.9 MiB)  TX bytes:5285112 (5.0 MiB)

eth1.421  Link encap:Ethernet  HWaddr 00:50:56:02:01:01
          inet addr:192.168.21.27  Bcast:192.168.21.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:121205 errors:0 dropped:0 overruns:0 frame:0
          TX packets:99111 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:22135333 (21.1 MiB)  TX bytes:38047809 (36.2 MiB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:433838 errors:0 dropped:0 overruns:0 frame:0
          TX packets:433838 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:55787762 (53.2 MiB)  TX bytes:55787762
';
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