use warnings;
use lib 'lib';
use strict;
#use warnings;
use AutoLoader qw/AUTOLOAD/;
use Emsgd qw/diag/;
use Test::Spec ;
use NGNMS::OLD::DB;
use NGNMS::SubnetScanner;
use NGNMS::OLD::Util;
use File::Slurp;
use File::Copy;
use File::Path qw( make_path );



############ MOCK DB ##############
#my $mock_dbh = DBI->connect('dbi:SQLite:dbname=foo.sqlite', '', '', {AutoCommit => 1, RaiseError => 1, PrintError => 1});
#my $DB = NGNMS_DB->new($mock_dbh);
#sub clean_db {
#    my $tables_sqls = $mock_dbh->selectcol_arrayref("select 'drop table ' || name || ';' from sqlite_master where type = 'table' and name not like 'sqlite_%'");
#    #    Emsgd::diag($tables_sqls);
#    foreach my $s (@{$tables_sqls}) {
#        if ($s =~ /sqllite_/) {
#            $mock_dbh->do('delete from sqlite_sequence');
#        } else {
#            $mock_dbh->do($s);
#        }
#
#    }
#
#}
#sub import_fixture {
#    clean_db();
#    my $file = shift;
#    $/ = ';';
#    open FH, "<".$file;
#    while (<FH>) {
#        $mock_dbh->do($_);
#    }
#    close FH;
#}
############################ SUPPORT FUNC ###################################

my $TMP_DIR = 't/tmp';
if (!-d $TMP_DIR) {
    make_path $TMP_DIR or die "Failed to create path: $TMP_DIR";
}
my $Fixtures_dir = 't/fixtures/scanner';
my $interfaces;
my $excluded_nets;
sub clear_tmp {
    #    unlink glob "'./$TMP_DIR/*'";
};

sub block_has_high_link_ip ($$) {
    my $block = shift;
    my $ip = shift;
    my $high_link = NGNMS::OLD::Util::ip2num ($ip);
    for my $key (keys %$block) {
        #                                         Emsgd::diag($re->{$key}{'high_link'});
        if ($block->{$key}{'high_link'} eq $high_link) {
            return 1
        }
    }
    return 0
}
sub blocks_has_excude_nets ($) {
    my $block = shift;
    my $expect = join(',', @$excluded_nets);
    for my $key (keys %$block) {
        #                                         Emsgd::diag($re->{$key}{'high_link'});
        if ($block->{$key}{'exclude_nets'} ne $expect) {
            return 0
        }
    }
    return 1
}





#Emsgd::diag('################### TEST #########################################');
$excluded_nets = [
    '127.0.0.0/8',
    '169.254.0.0/16',
    '224.0.0.0/4',
    '255.255.255.255/32',
    '0.0.0.0/8',
    '213.34.86.0/27',
];

describe 'Prepare netwok block subs :: ' => sub {
        my ($DB, @re, @res, @nets, @expect, $scanner, @nets_src );

        before each => sub {

                clear_tmp;
                undef $DB;
                undef $scanner;
                $DB = mock();
                $DB->expects('getNetworksToScan')->returns(\@nets);
                $scanner = NGNMS::SubnetScanner->new({ DB => $DB });
            };
        ##############################################################
        it 'should skip /32 nets' => sub {
                # ----------------------------------------------------------
                @nets = qw(
                    10.0.0.1/32
                        10.1.0.0/24
                        10.0.1.1/32
                        10.10.0.0/16
                    );
                @expect = qw(
                    10.1.0.0/24
                    10.10.0.0/16
                    );
                @nets = map {
                    [ $_ ]
                }@nets; #convet nets to array of ['ip/mask']
                # ----------------------------------------------------------
                #        Emsgd::diag(\@nets);
                @re = $scanner->aggregate_nets();
                @res = NGNMS::OLD::Util::tests_print_net \@re;
                #        Emsgd::diag( \@res);
                is_deeply(\@res, \@expect);
            };

        ##############################################################
        it 'should agregate nets' => sub {
                # ----------------------------------------------------------
                @nets = qw(
                    192.168.5.105/24
                        192.168.5.117/24
                        172.17.133.11/24
                        213.34.86.20/255.255.255.224
                        10.254.254.254/24
                        192.168.20.1/25
                        192.168.20.150/25
                        192.168.1.1/23
                        192.168.2.128/23
                        10.0.1.1/32
                        192.168.3.1/24
                        172.18.133.1/30
                        172.18.133.5/30
                    );
                @expect = qw(
                    10.254.254.0/24
                        172.17.133.0/24
                        172.18.133.0/29
                        192.168.0.0/22
                        192.168.5.0/24
                        192.168.20.0/24
                        213.34.86.0/27
                    );
                @nets = map {
                    [ $_ ]
                }@nets; #convet nets to array of ['ip/mask']
                # ----------------------------------------------------------
                @re = $scanner->aggregate_nets();
                @res = NGNMS::OLD::Util::tests_print_net \@re;
                is_deeply(\@res, \@expect);
            };
        ####################################################################
        it 'should  split networks into subnets by requred mask  ' => sub {
                # ----------------------------------------------------------
                @nets = qw(
                    192.162.0.0/28
                    10.0.1.1/32
                    );
                @expect = qw(
                    192.162.0.0/30
                        192.162.0.4/30
                        192.162.0.8/30
                        192.162.0.12/30
                    );
                @nets = map {
                    [ $_ ]
                }@nets; #convet nets to array of ['ip/mask']
                # ----------------------------------------------------------
                @re = $scanner->aggregate_nets();
                @re = $scanner->split_nets(\@re, 30);
                @res = NGNMS::OLD::Util::tests_print_net \@re;
                is_deeply(\@res, \@expect);
            };
        ##################################################################
        it 'should split nets on /24 subnets by default' => sub {
                # ----------------------------------------------------------
                @nets = qw(
                    192.162.0.0/22
                    10.0.1.1/32
                    10.0.0.0/21
                    );
                @expect = qw(
                    10.0.0.0/24
                        10.0.1.0/24
                        10.0.2.0/24
                        10.0.3.0/24
                        10.0.4.0/24
                        10.0.5.0/24
                        10.0.6.0/24
                        10.0.7.0/24
                        192.162.0.0/24
                        192.162.1.0/24
                        192.162.2.0/24
                        192.162.3.0/24
                    );
                @nets = map {
                    [ $_ ]
                }@nets; #convet nets to array of ['ip/mask']
                # ----------------------------------------------------------
                @re = $scanner->aggregate_nets();
                @re = $scanner->split_nets(\@re);
                @res = NGNMS::OLD::Util::tests_print_net \@re;
                is_deeply(\@res, \@expect);
            };
        it 'should not split networks less then required mask' => sub {
                # ----------------------------------------------------------
                @nets = qw(
                    192.162.0.0/23
                    10.0.0.0/25
                    );
                @expect = qw(
                    10.0.0.0/25
                    192.162.0.0/24
                    192.162.1.0/24
                    );
                @nets = map {
                    [ $_ ]
                }@nets; #convet nets to array of ['ip/mask']
                # ----------------------------------------------------------
                @re = $scanner->aggregate_nets();
                @re = $scanner->split_nets(\@re, 24);
                @res = NGNMS::OLD::Util::tests_print_net \@re;
                is_deeply(\@res, \@expect);
            };

    };


################ FINAL TEST ########################################
describe 'Create netwok block from interface :: ' => sub {
        # ----------------------------------------------------------
        my @nets = qw(
            192.162.0.0/23
                5.105.240.106/32
                10.0.0.0/25
                127.0.0.1/32
                10.0.1.0/23
                10.0.1.5/23
                10.0.1.150/23
                10.0.1.238/23
            );
        @nets = map {
            [ $_ ]
        }@nets; #convet nets to array of ['ip/mask']
        # ----------------------------------------------------------
        my ($DB, @re, @res, $scanner);
        $DB = mock();
        #    $scanner = SubnetScanner->new($DB);
        before each => sub {
                clear_tmp;
                undef $scanner;
                $DB->expects('getNetworksToScan')->returns(\@nets);
                $scanner = NGNMS::SubnetScanner->new({ DB => $DB });
            };
        it 'should skip 32, aggreagete and split by /25' => sub {
                # ----------------------------------------------------------

                my @expect = qw(
                    10.0.0.0/25
                        10.0.0.128/25
                        10.0.1.0/25
                        10.0.1.128/25
                        192.162.0.0/25
                        192.162.0.128/25
                        192.162.1.0/25
                        192.162.1.128/25
                    );
                # ----------------------------------------------------------
                @re = $scanner->parse_nework_blocks(25);
                @res = NGNMS::OLD::Util::tests_print_net \@re;
                is_deeply(\@res, \@expect);
            };
        it 'should split by /24 by default' => sub {
                # ----------------------------------------------------------

                my @expect = qw(
                    10.0.0.0/24
                        10.0.1.0/24
                        192.162.0.0/24
                        192.162.1.0/24
                    );
                # ----------------------------------------------------------
                @re = $scanner->parse_nework_blocks();
                @res = NGNMS::OLD::Util::tests_print_net \@re;
                is_deeply(\@res, \@expect);
            };

    };
describe 'Interface owner :: ' => sub {
        my ($DB, $verbose, $scanner, @nets, @expect);
        $verbose = 1;

        before each => sub {
                clear_tmp;
                undef $DB;
                $DB = mock();
                #        undef @nets;
                undef $scanner;
                $DB->expects('getNetworksToScan')->returns(\@nets);
                $scanner = NGNMS::SubnetScanner->new({ DB => $DB, verbose => $verbose });
            };

        it 'should store uniq networks into netBlocks table' => sub {
                @nets = (
                    [ '192.168.3.5/24', '192.168.3.1' ],
                    [ '192.168.3.105/24', '192.168.3.10' ],
                    [ '192.168.0.105/24', '192.168.0.1' ],
                    [ '192.168.20.105/24', '192.168.15.1' ],
                    [ '192.168.0.105/22', '192.168.0.22' ],
                );
                @expect = qw(
                    192.168.0.0/22
                        192.168.0.0/24
                        192.168.3.0/24
                        192.168.20.0/24
                    );
                #        Emsgd::diag(\@nets);
                $scanner->aggregate_nets();
                my @a = Net::Netmask::dumpNetworkTable($scanner->netBlocks);
                my @res = NGNMS::OLD::Util::tests_print_net  \@a;
                is_deeply \@res, \@expect
            };
        it 'should store interfaces in netBlocks' => sub {
                @nets = (
                    [ '192.168.3.5/24', '192.168.3.1' ],
                    [ '192.168.0.105/24', '192.168.0.1' ],
                );
                @expect = qw(
                    192.168.0.1
                    192.168.3.1
                    );
                $scanner->aggregate_nets();
                my @a = Net::Netmask::dumpNetworkTable($scanner->netBlocks);
                my @res = map{
                    $_->{interface_ip}
                } @a;
                is_deeply \@res, \@expect
            };
        it 'should NOT store interfaceif it not in network' => sub {
                @nets = (
                    [ '192.168.3.5/24', '192.168.3.1' ],
                    [ '192.168.0.105/24', '192.168.220.1' ],
                );
                @expect = qw(
                    undef
                    192.168.3.1
                    );
                $scanner->aggregate_nets();
                my @a = Net::Netmask::dumpNetworkTable($scanner->netBlocks);
                my @res = map{
                    $_->{interface_ip} || 'undef'
                } @a;
                is_deeply \@res, \@expect
            };
        it 'should store interface with highest ip as subnet owner' => sub {
                @nets = (
                    [ '192.168.3.5/24', '192.168.3.1' ],
                    [ '192.168.3.105/24', '192.168.3.235' ],
                    [ '192.168.3.105/24', '192.168.3.105' ],
                );
                @expect = qw(
                    192.168.3.235
                    );
                $scanner->aggregate_nets();
                my @a = Net::Netmask::dumpNetworkTable($scanner->netBlocks);
                my @res = map{
                    $_->{interface_ip} || 'undef'
                } @a;
                is_deeply \@res, \@expect;
            };
        it 'should find interface owner by host IP' => sub {
                @nets = (
                    [ '192.168.3.5/24', '192.168.3.1' ],
                    [ '192.168.50.105/24', '192.168.50.235' ],
                    [ '192.168.50.105/24', '192.168.50.1' ],
                    [ '192.168.35.105/24', '192.168.35.105' ],
                );
                $scanner->aggregate_nets();
                is $scanner->getNetblockInterfaceIP('192.168.3.5'), '192.168.3.1';
                is $scanner->getNetblockInterfaceIP('192.168.3.150'), '192.168.3.1';
                is $scanner->getNetblockInterfaceIP('192.168.3.1'), '192.168.3.1';
                is $scanner->getNetblockInterfaceIP('192.168.50.15'), '192.168.50.235';
                is $scanner->getNetblockInterfaceIP('192.168.50.235'), '192.168.50.235';
                is $scanner->getNetblockInterfaceIP('192.168.35.2'), '192.168.35.105';
                is $scanner->getNetblockInterfaceIP('192.168.5.2'), undef; #no such network
            };
    };

describe 'RANGE::' => sub {
        my ($DB, $verbose, $scanner);
        $verbose = 1;
        $DB = mock();
        my $filename = 'in.txt';
        my @nets = qw(
            10.0.0.0/24
            10.0.1.0/24
            192.162.0.0/24
            192.162.1.0/24
            );
        before each => sub {
                clear_tmp;
                undef $scanner;
                $scanner = NGNMS::SubnetScanner->new({ verbose => $verbose, workdir => $TMP_DIR, rangefile => $filename });
            };

        it 'should create rages file' => sub {
                $scanner->create_range_file( \@nets);
                ok open FILE, $TMP_DIR.'/'.$filename;
            };

        it 'should fill range file' => sub {
                $scanner->create_range_file(\@nets);
                my @res = read_file $TMP_DIR.'/'.$filename, chomp => 1;
                is_deeply  \@res, \@nets;

            }
    };
describe 'EXCLUDE::' => sub {
        clear_tmp;
        my ($DB, $verbose, $scanner);
        $verbose = 1;
        $DB = mock();
        my $filename = 'exc.txt';
        my @nets = qw(
            192.162.0.0/23
            5.105.240.106/32
            );
        before each => sub {
                clear_tmp;
                undef $scanner;
                $DB->expects('getScanException')->returns(\@nets);
                $scanner = $scanner = NGNMS::SubnetScanner->new({ DB => $DB, verbose => $verbose, workdir => $TMP_DIR,
                    excludefile                               => $filename });
            };
        it 'should create excludes file' => sub {
                $scanner->create_exclude_file( );
                ok open FILE, $TMP_DIR.'/'.$filename;
            };

        it 'should fill excludes file' => sub {
                $scanner->create_exclude_file();
                my @res = read_file $TMP_DIR.'/'.$filename, chomp => 1;
                is_deeply  \@res, \@nets;

            }
    };




###################### REGRESS ###########################################
describe 'Regress:: /192 and 127,128 hosts' => sub {
        my ($DB, @re, @res, @nets, @expect, $scanner, @nets_src );

        before each => sub {

                clear_tmp;
                undef $DB;
                undef $scanner;
                $DB = mock();
                $DB->expects('getNetworksToScan')->returns(\@nets);
                $scanner = NGNMS::SubnetScanner->new({ DB => $DB });
            };
        it 'should skip insane nets (/16 and bigger)';
        it 'should skip netw by excludewildcard masks' => sub {
                @nets = (
                    [ '192.162.0.0/23', '192.168.1.1' ],
                    [ '128.0.0.2/192.0.0.1', '192.168.1.1' ],
                    [ '10.128.0.1/24', '192.168.1.1' ],
                    [ '10.0.0.127/24', '192.168.1.1' ],
                    [ '127.0.0.1/8', '192.168.1.1' ],
                );
                @expect = qw(
                    10.0.0.0/24
                    10.128.0.0/24
                    192.162.0.0/23
                    );
                $scanner->excludewildcard(qr/^127|^128/);
                @re = $scanner->aggregate_nets();
                @res = NGNMS::OLD::Util::tests_print_net \@re;
                is_deeply(\@re, \@expect);

            };
    };

describe "Scan up to 10 network-blocks " => sub{

        my ($DB, @re, @res, @nets, @expect, $scanner, @nets_src );

        before each => sub {

                clear_tmp;
                undef $DB;
                undef $scanner;
                $DB = mock();
                $scanner = NGNMS::SubnetScanner->new({ DB => $DB });
            };
        it "should spilt all nets up to 10 chunks" => sub {
                @nets = (
                    [ '10.1.0.127/24', '192.168.1.1' ],
                    [ '10.2.0.127/24', '192.168.1.1' ],
                    [ '10.3.0.127/24', '192.168.1.1' ],
                    [ '10.4.0.127/24', '192.168.1.1' ],
                    [ '10.5.0.127/24', '192.168.1.1' ],
                    #                    [ '10.6.0.127/24', '192.168.1.1' ],
                    #                    [ '10.7.0.127/24', '192.168.1.1' ],
                    #                    [ '10.8.0.127/24', '192.168.1.1' ],
                    #                    [ '10.9.0.127/24', '192.168.1.1' ],
                    #                    [ '10.10.0.127/24', '192.168.1.1' ],
                    #                    [ '10.11.0.127/24', '192.168.1.1' ],
                    #                    [ '10.12.0.127/24', '192.168.1.1' ],
                    #                    [ '10.13.0.127/24', '192.168.1.1' ],
                    #                    [ '10.14.0.127/24', '192.168.1.1' ],
                    #                    [ '10.15.0.127/24', '192.168.1.1' ],
                );
                @expect = (
                    [
                        [
                            '10.1.0.127/24',
                            '192.168.1.1'
                        ],
                        [
                            '10.2.0.127/24',
                            '192.168.1.1'
                        ]
                    ],
                    [
                        [
                            '10.3.0.127/24',
                            '192.168.1.1'
                        ],
                        [
                            '10.4.0.127/24',
                            '192.168.1.1'
                        ]
                    ],
                    [
                        [
                            '10.5.0.127/24',
                            '192.168.1.1'
                        ]
                    ]
                );
                my @re = $scanner->get_chunks_to_scan(\@nets, 3);
#                Emsgd::diag \@re;
                is_deeply(\@re, \@expect);
            }
    };

runtests unless caller;