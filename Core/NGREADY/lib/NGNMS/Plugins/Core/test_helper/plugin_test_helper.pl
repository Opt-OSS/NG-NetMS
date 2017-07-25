#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::Spec;
use Emsgd qw(diag);
use Module::Load;
use Carp;
use Text::Diff;
my ( $plugin, $module );

#@returns NGNMS::App::PollHostPluginInterface
sub get_plugin_new {
    $plugin = undef;
    return module()->new;
}

sub test_db_clean {
    my NGNMS::DB $db = shift;
    local $db->dbh->{PrintWarn};
    $db->dbh->do('truncate table routers cascade ');
}

sub get_expect {
    my $exp = shift;
    my $device = shift;
    my $fp = fixtures."/".$device."/expect/$exp.pl";

    #    diag ($fp);
    my $r = do $fp;
    return $r;
}

$module = "NGNMS::Plugins::Core::".vendor."::PollHost";

shared_examples_for "implement required methods" => sub {
        it vendor.":: should implement required methods" => sub {
                can_ok(
                    get_plugin_new(), qw(
                        checkCanPollHost
                            checkSNMPsysObjectID
                            checkDeviceSupported
                            prepare_connection
                            beforeProcessing

                            getModel
                            getVendor
                            getHostName
                            getHardware
                            getSoftware
                            getLocation
                            getInterfaces
                            getConfig
                        )
                );
            };
    };
shared_examples_for "implement device support" => sub {
        describe "Support device:: " => sub {
                before each => sub {
                        $plugin = get_plugin_new();
                    };
                it "Supports PollHost mode".vendor => sub {
                        ok $plugin->checkCanPollHost();
                    };
                it "checkDeviceSupported :: should accept '".vendor
                        ."' UpperCase as command line host type" => sub {
                        ok $plugin->checkDeviceSupported(vendor);
                    };
                it "checkDeviceSupported :: should accept '"
                        .lc(vendor)
                        ."' LowerCase as command line host type" => sub {
                        ok $plugin->checkDeviceSupported( lc(vendor) );
                    };
                it "getVendor" => sub {
                        is $plugin->getVendor(), vendor;
                    };
            };
    };
#################### DEVICE SPECIFIC PARSERS ###########################

shared_examples_for "implements device info" => sub {
        my $devices = devices();
        while ( my ( $device, $params ) = each(%$devices) ) {

            describe "$device info::" => sub {

                    before each => sub {

                            #                            diag(fixtures.'/'.$device);
                            my $session =
                                NGNMS::Net::Emulator::Session->new(
                                    play_dir => fixtures.'/'.$device );

                            $plugin = get_plugin_new();
                            $plugin->session($session);
                            $plugin->stubs( _getSNMPsysObjectID0_asString =>
                                $params->{sysObjectID_0_string} );
                        };
                    it "checkSNMPsysObjectID[".$params->{sysObjectID_0}."]" => sub {

                            ok $plugin->checkSNMPsysObjectID( $params->{sysObjectID_0} );
                        };
                    xit "should getLocation";

                    it "should getHostName" => sub {
                            is $plugin->getHostName(), get_expect( 'getHostName', $device );
                        };

                    it "should getModel" => sub {
                            is $plugin->getModel(), get_expect( 'getModel', $device );
                        };
                    it "should getHardware" => sub {
                            my @sorted = sort { $b->{hw_item} cmp $a->{hw_item} }
                                @{ $plugin->getHardware() };

#                                                                diag (\@sorted );
                            my @expect = sort { $b->{hw_item} cmp $a->{hw_item} }
                                @{ get_expect( 'getHardware', $device ) };
                            is_deeply \@sorted, \@expect;
                        };
                    it "should  getSoftware" => sub {
                            my @sorted = sort { $b->{sw_item} cmp $a->{sw_item} }
                                @{ $plugin->getSoftware() };

#                                                                    diag $plugin->getSoftware();
                            my @expect = sort { $b->{sw_item} cmp $a->{sw_item} }
                                @{ get_expect( 'getSoftware', $device ) };
                            is_deeply \@sorted, \@expect;
                        };
                    it "should  getConfig" => sub {
                            $a = $plugin->getConfig();
                            $b = get_expect( 'getConfig', $device );
                            #                                                        diag $b;
                            #                    diag \@diff;
                            ok defined($a);
                            if (defined($a)) {
                                my @diff = diff \$a, \$b;
                                isnt $a, '';
                                is_deeply \@diff, [ '' ];
                            }
                        };

                };
            describe "$device interface::" => sub {

                    before each => sub {
                            my $session =
                                NGNMS::Net::Emulator::Session->new(
                                    play_dir => fixtures.'/'.$device );

                            $plugin = get_plugin_new();
                            $plugin->session($session);
                        };

                    it "getInterfaces : Physical" => sub {
                            my ( $ph_if, $ifc ) = $plugin->getInterfaces();
                            my $if_zero = $ph_if->{(keys(%$ph_if))[0]};

#                                          diag $ph_if;
                            #              diag $if_zero;
                            for my $key (qw /speed mtu state condition description/) {
                                ok defined($if_zero->{$key}),
                                    "$device interface:: getInterfaces : Physical structure has '$key' key";
                            }
                            is_deeply $ph_if, get_expect( 'getPhysicalInterfaces', $device );
                        };
                    it "getInterfaces : Logical" => sub {
                            my ( $ph_if, $ifc ) = $plugin->getInterfaces();

#                                                                    diag $ifc;
                            is_deeply $ifc, get_expect( 'getLogicalInterfaces', $device );

                        };
                }

        }
    };

1;
