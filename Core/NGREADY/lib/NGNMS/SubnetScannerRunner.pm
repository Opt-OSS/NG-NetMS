package NGNMS::SubnetScannerRunner;

use strict;
use warnings FATAL => 'all';

use Emsgd qw/diag/;
use NGNMS::DB;
use NGNMS::SubnetScanner;
use File::Slurp ;
use Parallel::ForkManager;
use Moo;
use MooX::Options;
use File::Path qw( make_path );

with "NGNMS::DB::CommandLineOptions";
with "NGNMS::App::Database";
with "NGNMS::Log4Role";

option verbose_level => (
        is      => 'ro',
        short   => "v",
        format  => 's',
        default => "0",
        doc     => "verbose level:  0-2"
    );

option dryrun => (
        is          => 'rw',
        default     => sub {0},
        negativable => 1,
        doc         => "do not perform real scan"
    );
option workdir => (
        is          => 'rw',
        default     => sub {$ENV{"NGNMS_HOME"}.'/tmp'},
        negativable => 1,
        doc         => "path to directory where to store working files"
    );

sub run{
    my $self = shift;
    $self->logger->debug("Start scanning...");

    $self->setup_database();
    make_path  $self->workdir;
    my $options = {
        DB            => $self->get_db,
        verbose_level => $self->verbose_level,
        dryrun        => $self->dryrun(),
        workdir       => $self->workdir,
        'scan_engine' => 'nmap', #nmap | masscan
    };

    my (@nets, @nets_to_scan);
    my $scanner = NGNMS::SubnetScanner->new( $options );
    $scanner->clear_workdir;
    @nets = $scanner->parse_nework_blocks;
    #my @a = NGNMS_util::print_net ( \@nets );
    #Emsgd::diag (\@a);

    $scanner->create_exclude_file;
    my $cmd = $scanner->create_cmd;
    #spilt netw up to 10 subarrays so we could track execution
    #Emsgd::diag $cmd;

    my @chunks = $scanner->get_chunks_to_scan(\@nets, 10);
    my $chunk_counter=0;
    my $chunks_total=scalar(@chunks);
    $self->logger->info("About to scan ".scalar(@nets)." networks in $chunks_total chunks");
    for my $chunk (@chunks) {

        $chunk_counter = $chunk_counter + 1;
        $self->logger->debug("Scanning chunk $chunk_counter of $chunks_total");
        $scanner->create_range_file( $chunk );
        my $fh;
        open( $fh, '-|', 'sudo '.$cmd ) || die 'cant execute scan command';
        $scanner->execute_scan( $fh, $chunk_counter );
        close($fh);
        my $step_percent = $chunk_counter / $chunks_total;
        $scanner->updateDiscoveryStatus(50 + 40*$step_percent, 0);
    }

    $scanner->prepare_result( $scanner->hostsfile_raw, $scanner->hostsfile );
    my @hosts = File::Slurp::read_file $scanner->workdir.'/'.$scanner->hostsfile, chomp => 1;
    $self->logger->warn("No hosts found networks scanning, polling of new hosts skipped") && $self->finalize() && return unless scalar(@hosts);
    #Emsgd::diag (\@hosts);
    $scanner->process_result( \@hosts );
    my @poll_hosts = File::Slurp::read_file $scanner->workdir.'/'.$scanner->pollfile, chomp => 1;
    $self->logger->info("About to poll ".scalar(@hosts)." scan-discovered hosts");
    #diag ( \@poll_hosts );


    ############# POLL IN PARALLELL #####################
    $| = 1; #set autoflush buffer;
    my $max_procs = 10; #max parallel polls
    #my @cmd_poll = ("$ENV{'NGNMS_HOME'}/bin/poll_host.pl");
    #my $hosts_to_poll = $#poll_hosts;
    #my $hosts_polled = 0;
    #
    #push @cmd_poll, '-d';
    #push @cmd_poll, '-L';
    #push @cmd_poll, $DB_host;
    #push @cmd_poll, '-D';
    #push @cmd_poll, $DB_name;
    #push @cmd_poll, '-U';
    #push @cmd_poll, $DB_user;
    #push @cmd_poll, '-W';
    #push @cmd_poll, $DB_passwd;
    #push @cmd_poll, '-P';
    #push @cmd_poll, $DB_port;

    my @cmd_poll = ("$ENV{'NGNMS_HOME'}/bin/AppRun.pl");
    my $hosts_to_poll = $#poll_hosts;

    push @cmd_poll, '--mode';
    push @cmd_poll, 'poll-host';
    push @cmd_poll, '-L';
    push @cmd_poll, $self->dbhost;
    push @cmd_poll, '-D';
    push @cmd_poll, $self->dbname;
    push @cmd_poll, '-U';
    push @cmd_poll, $self->dbuser;
    push @cmd_poll, '-W';
    push @cmd_poll, $self->dbpassword;
    push @cmd_poll, '-P';
    push @cmd_poll, $self->dbport;
#    push @cmd_poll, '--verbose_level';
#    push @cmd_poll, $self->verbose_level;

    my $pm = Parallel::ForkManager->new( $max_procs );

    $pm->run_on_finish( sub {
        my ($pid, $exit_code, $ident) = @_;
        $self->logger->debug ( "$ident just got out of the pool with PID $pid and exit code: $exit_code" );
        #    $hosts_polled++;
        #   $scanner->updateDiscveryStatus(70 + $hosts_polled*100*0.3/$hosts_to_poll,0);

    } );

    $pm->run_on_start( sub {
        my ($pid, $ident) = @_;
        $self->logger->debug   ( "** $ident started, pid: $pid" );
    } );

    $pm->run_on_wait( sub {
            $self->logger->debug  ( "** Waiting for a child process to finish ..." );
        },
        5
    );

    NAMES:
    foreach my $child (0 .. $hosts_to_poll) {
        my $pid = $pm->start( $poll_hosts[$child] ) and next NAMES;

        # This code is the child process

        $self->logger->debug  ( "This is $poll_hosts[$child], Child number $child" );
        system( @cmd_poll, ('--host', $poll_hosts[$child]) );
        $pm->finish( $child ); # pass an exit code to finish
    }

    $self->logger->debug  ( "Waiting for all children processes to complete...\n" );
    $pm->wait_all_children;
    $self->logger->info ( "Everybody is out of the pool!\n" );
    #TODO connection could be closed by timeout. Should check and reopen
    $self->finalize();
    return 1
}
sub finalize{
    my $self = shift;
    #Here connection could be closed, reopen if needed
    $self->setup_database;
    $self->DB->updateDiscoveryStatus ( 100, 1 );
    $self->logger->info("Subnets scaner finished");
    return 1;
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
