use lib '../lib/';
use strict;
use warnings FATAL => 'all';
#use warnings;
use Emsgd;
use Test::More ; #for syntax only
use Test::MockModule;#for syntax only
use Test::Spec ;
use NGNMS::OLD::Linux;

##################### !!!!!!!!!!!!!!!!!!!!!!!!!!!
#todo  Check against RHEL 2.x  AND 3.x Kernels output
=for
    Check against RHEL 2.x  AND 3.x Kernels output
ens192: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.3.121  netmask 255.255.255.0  broadcast 192.168.3.255
        inet6 fe80::20c:29ff:fe32:76f8  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:32:76:f8  txqueuelen 1000  (Ethernet)
        RX packets 9034  bytes 616487 (602.0 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1628  bytes 170307 (166.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0


virbr0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 192.168.122.1  netmask 255.255.255.0  broadcast 192.168.122.255
        ether 52:54:00:cf:e8:6f  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
eth0      Link encap:Ethernet  HWaddr 00:0c:29:8c:2f:8a
          inet addr:192.168.3.128  Bcast:192.168.3.255  Mask:255.255.255.0
          inet6 addr: fe80::20c:29ff:fe8c:2f8a/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:207055 errors:0 dropped:0 overruns:0 frame:0
          TX packets:93385 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:171002171 (171.0 MB)  TX bytes:8560334 (8.5 MB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:130 errors:0 dropped:0 overruns:0 frame:0
          TX packets:130 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:13005 (13.0 KB)  TX bytes:13005 (13.0 KB)
=cut



########### Mock DB - no real writes #############################
my $mock_db = Test::MockModule->new( 'NGNMS_DB' );
$mock_db->mock( 'DB_writeTopology', sub {
        0
    } );
$mock_db->mock( 'DB_setHostVendorByIP', sub($$){
        0
    } );



######################## TEST FIXTURES #################################
my $mock_user = 'ngnms';
my $mock_pass = 'optoss';
my $mock_host = '192.168.3.117';
my $mock_enpassword = 'ena';
my $mock_access = 'SSH';
my $case_a_valid = {
    'responce'       => "
0.0.0.0         192.168.3.1     0.0.0.0         UG        0 0          0 eth0
172.0.0.0       172.17.133.10   255.0.0.0       UG        0 0          0 eth1
172.17.133.0    0.0.0.0         255.255.255.0   U         0 0          0 eth1
192.168.3.0     0.0.0.0         255.255.255.0   U         0 0          0 eth0
",
    'valid_host_ips' => {
        '192.168.3.1'   => '192.168.3.1',
        '172.17.133.10' => '172.17.133.10',
        '192.168.3.117' => '192.168.3.117'
    },
    'valid_links'    => {
        '192.168.3.117' => \[ '192.168.3.1:B', '172.17.133.10:B' ],
        '192.168.3.1'   => \[ ],
        '172.17.133.10' => \[ ]
    },
};




#todo implement test here and on top
xdescribe 'Interface parcer' => sub {
=for
eth0
eth0:1
eth0.100
ett0.100:10
vibr0-nic
=cut
        it 'Get Phisical iface # convert "eth0:0 | eth1.10" --> "eth0"';
        it 'Get Logical  iface without secondary IP # convert "eth0:0" --> "eth0"';
    };
describe "linux_get_topologies" => sub {
        before each => sub {
                Net::OpenSSH->stubs( {
                        'new'     => sub {
                            return bless( { }, "Net::OpenSSH" );
                        },
                        'error'   => sub {
                            return 0
                        },
                        'capture' => sub {
                            split( /^/m, $case_a_valid->{'responce'} )
                        },
                        'system'  => sub {
                            return 0
                        },
                    } );
            };
        #############################################
        it 'shouls pass valid Links and hosts to NGNMS_DB::DB_writeTopology' => sub {
                NGNMS::OLD::DB->expects( 'DB_writeTopology' )
                    ->returns( #Test::Spec::with not working with pakages, Classes only
                    sub {
                        my $arg1 = shift; # host name => ip addr
                        my $arg2 = shift;    # host name => ( host name1, host name2, ...)
                        is_deeply ( $arg1, $case_a_valid->{'valid_host_ips'} );
                        is_deeply ( $arg2, $case_a_valid->{'valid_links'} );
                    }
                )->exactly( 1 )->times;
                ok NGNMS::OLD::Linux::linux_get_topologies( $mock_host, $mock_user, $mock_pass, $mock_enpassword, $mock_pass );;
            };
        #############################################
        it 'shouls pass valid Links and hosts to NGNMS_DB::DB_writeTopology' => sub {
                NGNMS::OLD::DB->expects( 'DB_writeTopology' )
                    ->returns( #Test::Spec::with not working with pakages, Classes only
                    sub {
                        my $arg1 = shift; # host name => ip addr
                        my $arg2 = shift;    # host name => ( host name1, host name2, ...)
                        is_deeply ( $arg1, $case_a_valid->{'valid_host_ips'} );
                        is_deeply ( $arg2, $case_a_valid->{'valid_links'} );
                    }
                )->exactly( 1 )->times;
                ok NGNMS::OLD::Linux::linux_get_topologies( $mock_host, $mock_user, $mock_pass, $mock_enpassword, $mock_pass );;
            };
        it 'shouls pass valid hosts to NGNMS_DB::DB_setHostVendorByIP' => sub {
                NGNMS::OLD::DB->expects( 'DB_setHostVendorByIP' )
                    ->exactly( 1 )
                    ->returns(
                    sub {
                        my $rtId = shift;
                        my $vendor = shift;
                        is ( $rtId, $mock_host );
                        is ( $vendor, 'Linux' );
                    }
                );
                ok NGNMS::OLD::Linux::linux_get_topologies( $mock_host, $mock_user, $mock_pass, $mock_enpassword, $mock_pass );;
            };

    };

runtests unless caller;