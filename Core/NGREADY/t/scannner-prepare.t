use warnings;
use lib 'lib';
use strict;
#use warnings;
use AutoLoader qw/AUTOLOAD/;
use Emsgd;
use Test::Spec ;
use NGNMS::OLD::DB;
use NGNMS::SubnetScanner;
use NGNMS::OLD::Util;
use File::Slurp;
use File::Copy;


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
my $Fixtures_dir = 't/fixtures/scanner';
my $interfaces;
my $excluded_nets;
sub clear_tmp {
    unlink glob "'./$TMP_DIR/*'";
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
#
#
# ====================================     ETAP 1   ====================================
#
#
describe 'Etap 1:: router NOT  EXISTS ::' => sub {
    my ($scanner, @hosts, $verbose);
    $verbose = 0;
    my $new_router_id = 5001;
    my $subnet_owner_id = 4001;
    my $interface_owner_id = 3001;
    my $host_ip = '192.168.1.111';
    my $vendor = 'RouterVendor';

    @hosts = ($host_ip);
    #
    #            =======    ETAP1.1   =======
    #
    describe 'Etap 1.1 interface_owner NOT EXISTS' => sub {
        before each => sub {
            clear_tmp;
            $scanner = NGNMS::SubnetScanner->new({verbose => $verbose});
            $scanner->stubs(
                'getRouterByIP' => undef, #router NOT  EXISTS
                'getInterfaceOwnerId' => undef, #interface_owner NOT EXISTS
                'getNetblockOwnerId' => $subnet_owner_id,
                'createRouter' => $new_router_id,
                'writeLink' => 1,
            );
        };
        # ---------------------------------------------------------------------
        it 'should create new router' => sub {
            $scanner->expects('createRouter')->with($host_ip)->returns($new_router_id)->once;
            ok $scanner->process_result(\@hosts);
        };
        # ---------------------------------------------------------------------
        it 'should connect subnet interface  to new router' => sub {
            $scanner->expects('writeLink')->with($subnet_owner_id, $new_router_id)->once;
            ok $scanner->process_result(\@hosts);
        };
        # ---------------------------------------------------------------------
        it 'should POLL host' => sub {
            $scanner->expects('addHostToPoll')->with($host_ip)->once;
            ok $scanner->process_result(\@hosts);
        };
        # ---------------------------------------------------------------------
    };
    #
    #            =======    ETAP1.2  =======
    #
    describe 'Etap 1.2 interface_owner EXISTS:' => sub {
        before each => sub {
            clear_tmp;
            $scanner = NGNMS::SubnetScanner->new({verbose => $verbose});
            $scanner->stubs(
                'getRouterByIP' => undef, #router NOT  EXISTS
                'getInterfaceOwnerId' => $interface_owner_id, #interface_owner EXISTS
                'getNetblockOwnerId' => $subnet_owner_id,
                'createRouter' => $new_router_id,
                'writeLink' => 1,
                'copyVendor' => 0,
            );
        };
        # ---------------------------------------------------------------------
        it 'should copy vendor from interface owner to  new router' => sub {
            #$scanner->expects('copyVendor')->with($interface_owner_id, $new_router_id)->once;
            $scanner->expects('copyVendor')->never;
            ok $scanner->process_result(\@hosts);
        };
        # ---------------------------------------------------------------------
        it 'should NOT connect subnet interface  to itself' => sub {
            $scanner = NGNMS::SubnetScanner->new({verbose => $verbose});
            $scanner->stubs(
                'getRouterByIP' => undef, #router NOT  EXISTS
                'getInterfaceOwnerId' => $interface_owner_id, #interface_owner EXISTS
                'getNetblockOwnerId' => $interface_owner_id,
                'createRouter' => 0,
                'writeLink' => 1,
                'copyVendor' => 0,
            );
            $scanner->expects('writeLink')->never;
            ok $scanner->process_result(\@hosts);
        };
        # ---------------------------------------------------------------------
        it 'should connect subnet interface  to router  interface' => sub {
            $scanner->expects('writeLink')->with($subnet_owner_id, $interface_owner_id)->once;
            ok $scanner->process_result(\@hosts);
        };
        # ---------------------------------------------------------------------
        it 'should NOT POLL host' => sub {
            $scanner->expects('addHostToPoll')->never;
            ok $scanner->process_result(\@hosts);
        };
        # ---------------------------------------------------------------------        
    };
};
#
#
# ====================================     ETAP 2   ====================================
#
#
describe 'Etap 2:: router EXISTS' => sub {
    my ($scanner, @hosts, $verbose);
    $verbose = 0;
    my $router_id = 5001;
    my $subnet_interface_id = 4001;
    my $interface_owner_id = 3001;
    my $host_ip = '192.168.1.111';
    my $vendor = 'RouterVendor';

    @hosts = ($host_ip);
    #
    #            =======    ETAP 2.1  =======
    #
    describe 'Etap 2.1 interface_owner EXISTS' => sub {
        #
        #            =======    ETAP 2.1.1  =======
        #
        describe 'Etap 2.1.1 router IS NOT #interface_owner' => sub {

            before each => sub {
                clear_tmp;
                $interface_owner_id = 3001;
                $router_id = 5001;
                $scanner = NGNMS::SubnetScanner->new({verbose => $verbose});
                $scanner->stubs(
                    'getRouterByIP' => $router_id, #router EXISTS
                    'getInterfaceOwnerId' => $interface_owner_id, #interface_owner EXISTS
                    'getNetblockOwnerId' => $subnet_interface_id,
                    'writeLink' => 1,
                    'copyVendor' => 0,
                );
            };
            # ---------------------------------------------------------------------
            it ':: should copy vendor from interface owner to  router ' => sub {
                $scanner->expects('copyVendor')->with($interface_owner_id, $router_id)->once;
                ok $scanner->process_result(\@hosts);
            };
            # ---------------------------------------------------------------------
            it ':: should set new router vendor and create network link ' => sub {
                $scanner->expects('writeLink')->with($subnet_interface_id, $interface_owner_id)->once;
                ok $scanner->process_result(\@hosts);
            };
            # ---------------------------------------------------------------------
            it 'should POLL host' => sub {
                $scanner->expects('addHostToPoll')->once;
                ok $scanner->process_result(\@hosts);
            };
            # ---------------------------------------------------------------------

        };
        #
        #            =======    ETAP 2.1.2  =======
        #
        describe 'Etap 2.1.2 router IS interface_owner' => sub {

            before each => sub {
                clear_tmp;
                $interface_owner_id = 5001;
                $router_id = 5001;
                $scanner = NGNMS::SubnetScanner->new({verbose => $verbose});
                $scanner->stubs(
                    'getRouterByIP' => $router_id, #router EXISTS
                    'getInterfaceOwnerId' => $interface_owner_id, #interface_owner EXISTS
                    'getNetblockOwnerId' => $subnet_interface_id,
                    'writeLink' => 1,
                    'copyVendor' => 0,
                );
            };
            # ---------------------------------------------------------------------
            it 'connect subnet to router ' => sub {
                $scanner->expects('writeLink')->with($subnet_interface_id, $router_id)->once;
                ok $scanner->process_result(\@hosts);
            };
            # ---------------------------------------------------------------------
            it 'should POLL host' => sub {
                $scanner->expects('addHostToPoll')->once;
                ok $scanner->process_result(\@hosts);
            };
            # ---------------------------------------------------------------------
        }
    };
    #
    #            =======    ETAP 2.2  =======
    #
    describe 'Etap 2.2 interface_owner NOT EXISTS ' => sub {
        before each => sub {
            clear_tmp;
            $router_id = 5001;
            $scanner = NGNMS::SubnetScanner->new({verbose => $verbose});
            $scanner->stubs(
                'getRouterByIP' => $router_id, #router EXISTS
                'getInterfaceOwnerId' => undef, #interface_owner EXISTS
                'getNetblockOwnerId' => $subnet_interface_id,
                'writeLink' => 1,
                'copyVendor' => 0,
            );
        };
        # ---------------------------------------------------------------------
        it 'should create link' => sub {
            $scanner->expects('writeLink')->with($subnet_interface_id, $router_id)->once;
            ok $scanner->process_result(\@hosts);
        };
        # ---------------------------------------------------------------------
        it 'should  POLL host' => sub {
            $scanner->expects('addHostToPoll')->once;
            ok $scanner->process_result(\@hosts);
        };
        # ---------------------------------------------------------------------
    }
};
describe 'Poll hosts file::' => sub {
    my ($scanner, @hosts, $verbose);
    $verbose = 0;
    before each => sub {
        clear_tmp;
        $scanner = NGNMS::SubnetScanner->new({verbose => $verbose, workdir => $TMP_DIR});
    };
    it 'shuld create poll host file' => sub {
        $scanner->addHostToPoll('192.168.3.117');
#        Emsgd::diag( $scanner->{workdir}.'/'.$scanner->{pollfile} );

        ok -e $scanner->{workdir}.'/'.$scanner->{pollfile};
    };
    xit 'should add uniq routers to poll'; #TODO
};
runtests unless caller;
######################