#!/usr/bin/perl

use warnings FATAL => 'all';
use strict;

use Test::More;
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;

use NGNMS::App;

use NGNMS::Plugins::Core::Linux::PollHost;
use Emsgd qw(diag);




=header  host status
it should set right host status on any possible SNMP/ssh/nmap results combinations

=cut



sub test_db_clean($) {
    my NGNMS::DB $db = shift;
    local $db->dbh->{PrintWarn};
    $db->dbh->do( 'truncate table routers cascade ' );
}




describe "it shold set host status NO MANUAL TYPE::" => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        my $rt_id;
        before each => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 1,
                    'checkSNMPsysObjectID' => 1,
                );

                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => 'C2' );
                $app->stubs(
                    getTypeBySNMP   => 0,
                    processPollHost => 0,

                );
                $db = $app->get_db;
                $app->SessionClass( "NGNMS::Net::Emulator::Session" );
                test_db_clean($db);
                $rt_id = $db->addRouter( 'C2', '10.0.1.1', 1 );

            };


        ############## NO MANUAL TYPE
        ## when XXX = [snmp ssh type_in_DB]
        it "DO NMAP     when 000" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {return 0;},
                    processPollHost => sub {return 1},

                );
                $app->expects('doNmap')->once();
                my $res = $app->run();
                is  $res, 0;
            };
        it "DO NMAP     when 001" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {return 0;},
                    processPollHost => sub {return 1},

                );
                $app->expects('doNmap')->once();
                my $res = $app->run();
                is  $res, 0;
            };
        xit "ERROR       when 010 impossible if manual type is NOT provided " => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {return 0;},
                    processPollHost => sub {return 1},

                );

                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'ERROR' ];
            };
        it "UP          when 011 fallback to DB type" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {return 0;},
                    processPollHost => sub {return 1},

                );
                $db->setHostVendor($rt_id, 'Linux');
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Up' ];
            };
        it "UNMANAGED   when 100 and plugin exists" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {
                        $app->sysObjIdResult('UNDEF');
                        return 1;
                    },
                    processPollHost => sub {return 0},

                );
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Unmanaged' ];
            };
        it "UNSUPPORTED when 100 and plugin does NOT exists" => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 0,
                    'checkSNMPsysObjectID' => 0,
                );
                $app->stubs(
                    getTypeBySNMP   => sub {
                        $app->sysObjIdResult('UNDEF');
                        return 1;
                    },
                    processPollHost => sub {return 0},

                );
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Unsupported' ];
            };;
        it "UNMANAGED   when 101" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {
                        $app->sysObjIdResult('UNDEF');
                        return 1;
                    },
                    processPollHost => sub {return 0},

                );
                $db->setHostVendor($rt_id, 'Linux');
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Unmanaged' ];
            };;
        it "UP          when 110" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {
                        $app->sysObjIdResult('UNDEF');
                        return 1;
                    },
                    processPollHost => sub {return 1},

                );
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Up' ];

            };
        it "UP          when 111" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {
                        $app->sysObjIdResult('UNDEF');
                        return 1;
                    },
                    processPollHost => sub {return 1},

                );
                $db->setHostVendor($rt_id, 'Linux');
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Up' ];
            };
    };
describe "it shold set host status WITH MANUAL TYPE::" => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        my $rt_id;
        before each => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 1,
                    'checkSNMPsysObjectID' => 1,
                );

                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => 'C2' );
                $app->stubs(
                    getTypeBySNMP   => 0,
                    processPollHost => 0,

                );
                $db = $app->get_db;
                $app->SessionClass( "NGNMS::Net::Emulator::Session" );
                test_db_clean($db);
                $rt_id = $db->addRouter( 'C2', '10.0.1.1', 1 );

            };
        ############## WITH MANUAL TYPE
        ## [snmp ssh]
        it "DO NMAP     when 00" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {
                        $app->sysObjIdResult('UNDEF');
                        return 0;
                    },
                    processPollHost => sub {return 0},

                );
                $app->host_type('Linux');
                $app->expects('doNmap')->once();
                my $res = $app->run();
                is  $res, 0;

            };;
        it "UP          when 01" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {
                        $app->sysObjIdResult('UNDEF');
                        return 0;
                    },
                    processPollHost => sub {return 1},

                );
                $app->host_type('Linux');
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Up' ];
            };
        it "UNMANAGED   when 10 and plugin exists" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {
                        $app->sysObjIdResult('UNDEF');
                        return 1;
                    },
                    processPollHost => sub {return 0},

                );
                $app->host_type('Linux');
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Unmanaged' ];
            };
        it "UNSUPPORTED when 10 and plugin does NOT exists" => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 0,
                    'checkSNMPsysObjectID' => 0,
                );
                $app->stubs(
                    getTypeBySNMP   => sub {
                        $app->sysObjIdResult('UNDEF');
                        return 1;
                    },
                    processPollHost => sub {return 0},

                );
                $app->host_type('Linux');
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Unsupported' ];
            };
        it "UP          when 11" => sub {
                $app->stubs(
                    getTypeBySNMP   => sub {
                        $app->sysObjIdResult('UNDEF');
                        return 1;
                    },
                    processPollHost => sub {return 1},

                );
                $app->host_type('Linux');
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Up' ];
            };;
    };
describe "it shold set host status via NMAP::" => sub {
        my NGNMS::App $app;
        my NGNMS::DB $db;
        my $rt_id;
        before each => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 1,
                    'checkSNMPsysObjectID' => 1,
                );

                NGNMS::App->_clear_instance;
                $app = NGNMS::App->instance( mode => 'poll-host', dbname => 'ngnms_test', dbhost => 'ngnms-psql',
                    host                          => 'C2' );
                $app->stubs(
                    getTypeBySNMP   => 0,
                    processPollHost => 0,

                );
                $db = $app->get_db;
                $app->SessionClass( "NGNMS::Net::Emulator::Session" );
                test_db_clean($db);
                $rt_id = $db->addRouter( 'C2', '10.0.1.1', 1 );

            };
        ############### DO NMAP
        ## [nmap type_in_DB]
        it "UNKNOWN     when 00" => sub {
                NGNMS::Net::Nmap->stubs(getNmapResponse => sub {return 0});

                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Unknown' ];
            };
        it "down        when 01" => sub {
                NGNMS::Net::Nmap->stubs(getNmapResponse => sub {return 0});

                $db->setHostVendor($rt_id, 'Linux');
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Down' ];
            };;
        it "NEW     when 10" => sub {
                NGNMS::Net::Nmap->stubs(getNmapResponse => sub {return 1});

                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'New' ];
            };
        it "UNMANAGED   when 11 and plugin exists" => sub {
                NGNMS::Net::Nmap->stubs(getNmapResponse => sub {return 1});

                $db->setHostVendor($rt_id, 'Linux');
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Unmanaged' ];
            };
        it "UNSUPPORTED   when 11 and plugin does NOT exists" => sub {
                NGNMS::Plugins::Core::Linux::PollHost->stubs(
                    'checkDeviceSupported' => 0,
                    'checkSNMPsysObjectID' => 0,
                );
                NGNMS::Net::Nmap->stubs(getNmapResponse => sub {return 1});
                $db->setHostVendor($rt_id, 'Linux');
                my $res = $app->run();
                my $r = $db->dbh->selectcol_arrayref( "select status from routers where router_id=$rt_id" );
                is_deeply $r, [ 'Unsupported' ];
            };

    };

runtests unless caller;;

