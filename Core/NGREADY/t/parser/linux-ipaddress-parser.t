use strict;
use warnings FATAL => 'all';
#use warnings;
use AutoLoader qw/AUTOLOAD/;

use Test::More ; #for syntax only
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;
use File::Slurp qw(read_file);

use Emsgd qw (diag);

use NGNMS::OLD::Linux;

my ( $dbname, $dbuser, $dbpasswd, $dbport, $dbhost ) = qw( ngnms_test ngnms  optoss 5432  ngnms-psql);
my $Fixtures_dir = 't/fixtures/interface_parser/linux/ip_address';



#====================================== Helper functions ======================
describe 'get_interfa_state::' => sub {
        it 'should get state from ip addr show ' => sub {
                my $d;
                $d = NGNMS::OLD::Linux->get_interfa_state( "<LOOPBACK,UP,LOWER_UP>" );
                is  $d, 'up';
                $d = NGNMS::OLD::Linux->get_interfa_state( "<BROADCAST,MULTICAST,UP,LOWER_UP>" );
                is  $d, 'up';
                $d = NGNMS::OLD::Linux->get_interfa_state( "<BROADCAST,MULTICAST,DOWN,LOWER_UP>" );
                is  $d, 'down';
                $d = NGNMS::OLD::Linux->get_interfa_state( "<BROADCAST,MULTICAST,LOWER_UP>" );
                is  $d, 'unknown';
                $d = NGNMS::OLD::Linux->get_interfa_state( "<BROADCAST,MULTICAST,LOWER_UP>" );
                is  $d, 'unknown';
                $d = NGNMS::OLD::Linux->get_interfa_state( "<NO-CARRIER,BROADCAST,MULTICAST,UP>" );
                is  $d, 'up';
                $d = NGNMS::OLD::Linux->get_interfa_state( "<BROADCAST,MULTICAST>" );
                is  $d, 'unknown';

            };
    };


describe 'split_inteface_name::' => sub {
        it 'split ifname intop logical and physical if "@" in name' => sub {

                my $d = NGNMS::OLD::Linux->split_inteface_name( 'test_vlan_41@eth1' );
                is_deeply $d, { 'logical_name' => 'test_vlan_41', 'physical_name' => 'eth1' };
            };
        it 'split return same for logical and physical if "@" not present' => sub {
                my $d = NGNMS::OLD::Linux->split_inteface_name( 'test_vlan_41' );
                is_deeply $d, { 'logical_name' => 'test_vlan_41', 'physical_name' => 'test_vlan_41' };
            }
    };
describe 'linux_parse_speed_interface::' =>sub{
        it 'should return data ftom ethtool'=>sub{
                 NGNMS::OLD::Linux->expects('linux_cmd')->returns('10000Mb/s');
                my $d = NGNMS::OLD::Linux->linux_parse_speed_interface('eth1');
                is $d,'10000Mb/s';
            }
    };
#====================================== REAL INTERFACES ======================

describe "RH virbr interfaces" => sub {
        it "should find state UP in the end of line" => sub {
                my $ifs = '
5: virbr0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN
    link/ether 52:54:00:cf:e8:6f brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
       valid_lft forever preferred_lft forever
6: virbr0-nic: <BROADCAST,MULTICAST> mtu 1500 qdisc pfifo_fast master virbr0 state DOWN qlen 500
    link/ether 52:54:00:cf:e8:6f brd ff:ff:ff:ff:ff:ff
                ';
                my $expect_ph_int = {
                    'virbr0'     => {
                        'description' => '52:54:00:cf:e8:6f',
                        'state'       => 'up',
                        'condition'   => 'disabled'
                    },
                    'virbr0-nic' => {
                        'condition'   => 'disabled',
                        'state'       => 'unknown',
                        'description' => '52:54:00:cf:e8:6f'
                    }
                };
                my ($ph_if, $ifc ) = NGNMS::OLD::Linux->parse_interfaces( $ifs );
                #                diag ( $ph_if );
                is_deeply( $ph_if, $expect_ph_int )
            };

    };

describe 'linux_processing cmd "ip address"::' => sub {
        ########### CENTOS #########################
        #    $ uname -a
        #    Linux web1.offpista.com 2.6.32-504.30.3.el6.i686 #1 SMP Wed Jul 15 10:55:56 UTC 2015 i686 i686 i386 GNU/Linux
        #    $ cat /etc/redhat-release
        #    CentOS release 6.7 (Final)
        it "Ubuntu 14.04.4 LTS::00" => sub {
                my $expect_ph_int = {
                    'eth0' => {
                        'state'       => 'up',
                        'description' => '00:50:56:2c:56:e2',
                        'condition'   => 'enabled'
                    },
                    'lo'   => {
                        'state'       => 'up',
                        'description' => '00:00:00:00:00:00',
                        'condition'   => 'UNKNOWN'
                    },
                    'eth1' => {
                        'state'       => 'up',
                        'description' => '00:50:56:20:d8:b9',
                        'condition'   => 'enabled'
                    }
                };
                my $expect_log_int = {
                    'lo'             => {
                        'physical_interface_name' => 'lo',
                        'ip'                      => '127.0.0.1',
                        'description'             => 'UNKNOWN',
                        'mask'                    => '255.0.0.0'
                    },
                    'test_vlan_41:1' => {
                        'physical_interface_name' => 'eth1',
                        'ip'                      => '192.168.2.21',
                        'description'             => 'enabled',
                        'mask'                    => '255.255.255.0'
                    },
                    'test_vlan_41:0' => {
                        'mask'                    => '255.255.255.0',
                        'description'             => 'enabled',
                        'physical_interface_name' => 'eth1',
                        'ip'                      => '192.168.1.21'
                    },
                    'eth1'           => {
                        'ip'                      => '10.10.100.21',
                        'physical_interface_name' => 'eth1',
                        'description'             => 'enabled',
                        'mask'                    => '255.255.255.0'
                    },
                    'eth0'           => {
                        'physical_interface_name' => 'eth0',
                        'ip'                      => '129.192.44.21',
                        'mask'                    => '255.255.255.192',
                        'description'             => 'enabled'
                    }
                };                                                                                                                                   ;
                my $text = File::Slurp::read_file $Fixtures_dir.'/Ubuntu-14-LTS-00.txt', chomp => 1;
                my ($ph_if, $ifc ) = NGNMS::OLD::Linux->parse_interfaces( $text );
                #                diag $ifc;
                is_deeply $ph_if, $expect_ph_int;
                is_deeply $ifc, $expect_log_int;
            };
        it "Ubuntu 14.04.4 LTS::01" => sub {
                my $expect_ph_int = {
                    'eth1' => {
                        'state'       => 'up',
                        'description' => '00:0c:29:7d:ac:50',
                        'condition'   => 'enabled'
                    },
                    'eth0' => {
                        'condition'   => 'enabled',
                        'description' => '00:0c:29:7d:ac:46',
                        'state'       => 'up'
                    },
                    'lo'   => {
                        'state'       => 'up',
                        'condition'   => 'UNKNOWN',
                        'description' => '00:00:00:00:00:00'
                    }
                };                                                   ;
                my $expect_log_int = {
                    'lo'        => {
                        'description'             => 'UNKNOWN',
                        'ip'                      => '127.0.0.1',
                        'physical_interface_name' => 'lo',
                        'mask'                    => '255.0.0.0'
                    },
                    'eth1.20:0' => {
                        'description'             => 'enabled',
                        'ip'                      => '172.17.20.11',
                        'mask'                    => '255.255.255.0',
                        'physical_interface_name' => 'eth1'
                    },
                    'eth0'      => {
                        'description'             => 'enabled',
                        'ip'                      => '192.168.3.117',
                        'mask'                    => '255.255.255.0',
                        'physical_interface_name' => 'eth0'
                    },
                    'eth1.10'   => {
                        'physical_interface_name' => 'eth1',
                        'mask'                    => '255.255.255.0',
                        'ip'                      => '172.17.133.11',
                        'description'             => 'enabled'
                    },
                    'eth1.20:1' => {
                        'physical_interface_name' => 'eth1',
                        'mask'                    => '255.255.255.0',
                        'ip'                      => '172.17.20.12',
                        'description'             => 'enabled'
                    }
                };                                                                                                                                                                                    ;
                my $text = File::Slurp::read_file $Fixtures_dir.'/Ubuntu-14-LTS-01.txt', chomp => 1;
                my ($ph_if, $ifc ) = NGNMS::OLD::Linux->parse_interfaces( $text );
                #                diag $ifc;
                #diag $ph_if;

                is_deeply $ph_if, $expect_ph_int;
                is_deeply $ifc, $expect_log_int;
            };
        it "Red Hat Enterprise Linux Server 7.2 (Maipo)" => sub {
                my $expect_ph_int = {
                    'virbr0-nic' => {
                        'condition'   => 'disabled',
                        'state'       => 'unknown',
                        'description' => '52:54:00:cf:e8:6f'
                    },
                    'lo'         => {
                        'description' => '00:00:00:00:00:00',
                        'condition'   => 'UNKNOWN',
                        'state'       => 'up'
                    },
                    'virbr0'     => {
                        'condition'   => 'disabled',
                        'state'       => 'up',
                        'description' => '52:54:00:cf:e8:6f'
                    },
                    'ens192'     => {
                        'description' => '00:0c:29:32:76:f8',
                        'state'       => 'up',
                        'condition'   => 'enabled'
                    },
                    'ens224'     => {
                        'description' => '00:0c:29:32:76:02',
                        'state'       => 'up',
                        'condition'   => 'enabled'
                    }
                };                                                                                                  ;
                my $expect_log_int = {
                    'virbr0'    => {
                        'mask'                    => '255.255.255.0',
                        'description'             => 'disabled',
                        'physical_interface_name' => 'virbr0',
                        'ip'                      => '192.168.122.1'
                    },
                    'ens192'    => {
                        'description'             => 'enabled',
                        'mask'                    => '255.255.255.0',
                        'ip'                      => '192.168.3.121',
                        'physical_interface_name' => 'ens192'
                    },
                    'ens224.10' => {
                        'description'             => 'enabled',
                        'mask'                    => '255.255.255.0',
                        'ip'                      => '172.17.133.129',
                        'physical_interface_name' => 'ens224'
                    },
                    'lo'        => {
                        'physical_interface_name' => 'lo',
                        'ip'                      => '127.0.0.1',
                        'mask'                    => '255.0.0.0',
                        'description'             => 'UNKNOWN'
                    }
                };
                my $text = File::Slurp::read_file $Fixtures_dir.'/RH-72-00.txt', chomp => 1;
                my ($ph_if, $ifc ) = NGNMS::OLD::Linux->parse_interfaces( $text );
                #diag $ifc;
                #diag $ph_if;
                is_deeply $ph_if, $expect_ph_int;
                is_deeply $ifc, $expect_log_int;
            }
    };
describe "Saving to DB Physical Interface (TEST DB operations)::" => sub {
        my $dbh;
        my $int = '
4: eth1.10@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 00:0c:29:7d:ac:50 brd ff:ff:ff:ff:ff:ff
    inet 172.17.133.11/24 brd 172.17.133.255 scope global eth1.10
       valid_lft forever preferred_lft forever
    inet 172.17.133.15/24 brd 172.17.133.255 scope global eth1.10
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe7d:ac50/64 scope link
       valid_lft forever preferred_lft forever
        ';
        my $rt_id;
        before each => sub {
                NGNMS::OLD::DB::DB_open( $dbname, $dbuser, $dbpasswd, $dbport, $dbhost );
                $dbh = NGNMS::OLD::DB::getDbh;
                NGNMS::OLD::DB::test_db_clean();
                $rt_id = NGNMS::OLD::DB::DB_addRouter( 'test_router', '1.1.1.1', 1 );
                NGNMS::OLD::Linux->expects('linux_parse_speed_interface')->returns('100Mb/s');

            };
        after each => sub {
                NGNMS::OLD::DB::DB_close();
            };
        it "should create new Pysical interface" => sub {
                my $expect = [
                    {
                        'state'     => 'up',
                        'speed'     => '100Mb/s',
                        'descr'     => '00:0c:29:7d:ac:50',
                        'condition' => 'enabled',
                        'name'      => 'eth1',
                        'router_id' => $rt_id,
                    }
                ];
                NGNMS::OLD::Linux->process_interfaces( $rt_id, $int );

                my $r = $dbh->selectall_arrayref( "select state,speed,descr,condition,name,router_id from ph_int", { Slice => { } } );
                #                diag $r;
                is scalar( @$r ), 1;
                is_deeply $r, $expect;
            };
        it "should update existed Pysical interface" => sub {
                my $phy_id = NGNMS::OLD::DB::DB_writePhInterface( $rt_id, {
                        'state'     => 'dowd',
                        'descr'     => 'AA:AA:AA',
                        'condition' => 'disabled',
                        'interface' => 'eth1',

                    } );
                my $expect = [
                    {
                        'state'     => 'up',
                        'speed'     => '100Mb/s',
                        'descr'     => '00:0c:29:7d:ac:50',
                        'condition' => 'enabled',
                        'name'      => 'eth1',
                        'ph_int_id' => $phy_id,
                        'router_id' => $rt_id,
                    }
                ];
                NGNMS::OLD::Linux->process_interfaces( $rt_id, $int );
                my $r = $dbh->selectall_arrayref( "select ph_int_id, state,speed,descr,condition,name,router_id from ph_int", { Slice => { } } );
                is scalar( @$r ), 1;
                is_deeply $r, $expect;

            };
        it "should delte existed Pysical interface if not found" => sub(){
                my $phy_id = NGNMS::OLD::DB::DB_writePhInterface( $rt_id, {
                        'state'     => 'dowd',
                        'descr'     => 'AA:AA:AA',
                        'condition' => 'disabled',
                        'interface' => 'eth000',

                    } );
                NGNMS::OLD::Linux->process_interfaces( $rt_id, $int );
                my $r = $dbh->selectall_arrayref( "select ph_int_id from ph_int where ph_int_id = $phy_id", { Slice => { } } );
                #                diag $r;
                is scalar( @$r ), 0;

            };
    };
describe "Saving to DB Logical Interface (TEST DB operations)::" => sub {
        my $dbh;
        my $int = '
4: eth1.10@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 00:0c:29:7d:ac:50 brd ff:ff:ff:ff:ff:ff
    inet 172.17.133.11/24 brd 172.17.133.255 scope global eth1.10
       valid_lft forever preferred_lft forever
    inet 172.17.133.15/24 brd 172.17.133.255 scope global eth1.10
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fe7d:ac50/64 scope link
       valid_lft forever preferred_lft forever
        ';
        my $rt_id;
        before each => sub {
                NGNMS::OLD::DB::DB_open( $dbname, $dbuser, $dbpasswd, $dbport, $dbhost );
                $dbh = NGNMS::OLD::DB::getDbh;
                NGNMS::OLD::DB::test_db_clean();
                $rt_id = NGNMS::OLD::DB::DB_addRouter( 'test_router', '1.1.1.1', 1 );
                NGNMS::OLD::Linux->expects('linux_parse_speed_interface')->returns('100Mb/s');
            };
        after each => sub {
                NGNMS::OLD::DB::DB_close();
            };
        it "should create new Logical interface" => sub {
                my $expect = [
                    {
                        'name'      => 'eth1.10:0',
                        'mask'      => '255.255.255.0',
                        'router_id' => $rt_id,
                        'ip_addr'   => '172.17.133.11',
                        'descr'     => 'enabled'
                    },
                    {
                        'name'      => 'eth1.10:1',
                        'mask'      => '255.255.255.0',
                        'ip_addr'   => '172.17.133.15',
                        'router_id' => $rt_id,
                        'descr'     => 'enabled'
                    }
                ];
                NGNMS::OLD::Linux->process_interfaces( $rt_id, $int );
                my $r = $dbh->selectall_arrayref( "select name,mask,router_id,ip_addr,descr from interfaces order by name", { Slice => { } } );
                #                diag $r;
                is scalar( @$r ), 2;
                is_deeply $r, $expect;
            };
        it "should bind to right Physical If" => sub {
                my $phy_id = NGNMS::OLD::DB::DB_writePhInterface( $rt_id, {
                        'state'     => 'dowd',
                        'descr'     => 'AA:AA:AA',
                        'condition' => 'disabled',
                        'interface' => 'eth1',

                    } );
                my $expect = [
                    {
                        'ph_int_id' => $phy_id
                    },
                    {
                        'ph_int_id' => $phy_id
                    }
                ];
                NGNMS::OLD::Linux->process_interfaces( $rt_id, $int );
                my $r = $dbh->selectall_arrayref( "select ph_int_id from interfaces order by name", { Slice => { } } );
                #                diag $r;
                is_deeply $r, $expect;

            };
        it "should update existed Logical interface" => sub {
                my $phy_id = NGNMS::OLD::DB::DB_writePhInterface( $rt_id, {
                        'state'     => 'dowd',
                        'descr'     => 'AA:AA:AA',
                        'condition' => 'disabled',
                        'interface' => 'eth1',

                    } );
                my $struct = {
                    'interface'   => 'eth1.10:0',
                    'ip address'  => '172.17.133.11',
                    'mask'        => '255.255.255.255',
                    'description' => 'disabled'
                };
                NGNMS::OLD::DB::DB_writeInterface( $rt_id, $phy_id, $struct );
                $struct = {
                    'interface'   => 'eth1.10:1',
                    'ip address'  => '172.17.133.15',
                    'mask'        => '255.255.255.255',
                    'description' => 'disabled'
                };
                NGNMS::OLD::DB::DB_writeInterface( $rt_id, $phy_id, $struct );
                my $expect = [
                    {
                        'name'      => 'eth1.10:0',
                        'mask'      => '255.255.255.0',
                        'ip_addr'   => '172.17.133.11',
                        'descr'     => 'enabled',
                    },
                    {
                        'name'      => 'eth1.10:1',
                        'mask'      => '255.255.255.0',
                        'ip_addr'   => '172.17.133.15',
                        'descr'     => 'enabled',
                    }
                ];
                NGNMS::OLD::Linux->process_interfaces( $rt_id, $int );
                my $r = $dbh->selectall_arrayref( "select name,mask,ip_addr,descr from interfaces order by name", { Slice => { } } );
                is scalar( @$r ), 2;
                is_deeply $r, $expect;

            };
        it "should delte existed Logical interface if not found" => sub(){
                my $phy_id = NGNMS::OLD::DB::DB_writePhInterface( $rt_id, {
                        'state'     => 'dowd',
                        'descr'     => 'AA:AA:AA',
                        'condition' => 'disabled',
                        'interface' => 'eth1',

                    } );
                #add not-exists intercase
                NGNMS::OLD::DB::DB_writeInterface( $rt_id, $phy_id, {
                        'interface'   => 'eth1.10:100',
                        'ip address'  => '172.17.133.100',
                        'mask'        => '255.255.255.255',
                        'description' => 'disabled'
                    } );
                NGNMS::OLD::Linux->process_interfaces( $rt_id, $int );
                my $r = $dbh->selectall_arrayref( "select ifc_id from interfaces where name='eth1.10:100'" , { Slice => { } } );
#                diag $r;
                is scalar( @$r ), 0;

            };
    };
describe "Should add networks :: "=>sub{
      it "should add logical interface's network";
        it "NOT should add  network if exists";
    };
runtests unless caller;