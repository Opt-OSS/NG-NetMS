use warnings;
use lib 'lib';
use strict;
#use warnings;
use AutoLoader qw/AUTOLOAD/;
use Emsgd;
use Test::More ; #for syntax only
use Test::MockModule;#for syntax only
use Test::Subroutines;
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




################ FINAL TEST ########################################

describe 'CREATE CMD::NMAP' => sub {
        my $verbose = 1;
        my $scanner;
        before each => sub {
                $scanner = NGNMS::SubnetScanner->new( { workdir => $TMP_DIR, verbose => $verbose, scan_engine => 'nmap' } );
            };
        it 'use nmap' => sub {
                my $filename = 'exc.txt';
                like $scanner->create_cmd(), qr#nmap#;
            };

        it 'should write grepable output -oG' => sub {
                like $scanner->create_cmd(), qr/-oG/;
            };
        it 'should NOT use  --send-eth ' => sub {
                #If host has some VLAN nmap fails to scan and stops scanning other networks
                unlike $scanner->create_cmd(), qr/--send-eth/;
            };
        it 'should add -sL if dryrun' => sub {
                $scanner->{dryrun} = 1;
                like $scanner->create_cmd(), qr/-sL/;
                $scanner->{dryrun} = 0;
                unlike $scanner->create_cmd(), qr/-sL/;
            };
        it 'should add excludes file ' => sub {
                my $filename = 'exc.txt';
                $scanner->{excludefile} = $filename;
                like $scanner->create_cmd(), qr#--excludefile\s+$TMP_DIR/$filename#;
            };
        it 'should add scan networks ' => sub {
                my $filename = 'rages.txt';
                $scanner->{rangefile} = $filename;
                like $scanner->create_cmd(), qr#-iL\s+$TMP_DIR/$filename#;
            };
    };

describe 'PREPARE :: ' => sub {

        my ($DB, @re, @res, $verbose, $scanner);
        my $mock_output_file = 't/fixtures/mock_console_output_nmap';

        $verbose = 1;

        before each => sub {

                clear_tmp;
                undef $DB;
                undef $scanner;
                undef @res;

                $scanner = NGNMS::SubnetScanner->new( { DB => $DB, verbose => $verbose, workdir => $TMP_DIR, scan_engine => 'nmap' } );
            };
        it 'writes to db while scannig' => sub {
                Emsgd::diag $scanner->{verbose};
                $scanner->expects( 'updateDiscoveryStatus' )->returns( 1 )->exactly( 7 );
                my $fh = IO::File->new( $mock_output_file, 'r' );
                fail 'Can not open fixture file'.$mock_output_file unless defined $fh;
                ok $scanner->execute_scan( $fh );
            };
        it 'pepares (get host,sort, uniq) raw output' => sub {

                my $in_filename = 'result_raw.txt';
                my $out_filename = 'result_prep.txt';
                #        Emsgd::diag( \@expect);
                copy $Fixtures_dir.'/nmap_scan_result', $TMP_DIR.'/'.$in_filename or fail  'Bad fixtures';

                ok $scanner->prepare_result( $in_filename, $out_filename );

                my @expect = read_file $Fixtures_dir.'/nmap_prepared_result', chomp => 1;
                @res = read_file $TMP_DIR.'/'.$out_filename, chomp => 1;
                is_deeply \@expect, \@res;
            }

    };

###################### REGRESS ###########################################


runtests unless caller;