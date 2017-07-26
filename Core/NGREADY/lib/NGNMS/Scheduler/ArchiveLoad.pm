package NGNMS::Scheduler::ArchiveLoad;

use NGNMS::Scheduler::Audit;
use Emsgd qw /diag ss/;
use strict;
use Moo;
use Time::HiRes qw (gettimeofday tv_interval);
use warnings FATAL => 'all';
with "NGNMS::Log4Role";
#@method
#@returns NGNMS::DB
has DB => (is => 'ro');
has archive_id => (
        is       => 'ro',
        required => 1,
    );
has archive_data => (
        is      => 'lazy',
        builder => 1,
    );
has archive_dir => (is => 'ro', default => ($ENV{NGNMS_DATA} || '.').'/archive');
has filename => (
        is => 'rw',
    );
has file_exists => (
        is      => 'rw',
        'lazy'  => 1,
        builder => 1,
    );
has gzipped => (
        is      => 'rw',
        default => 0
    );

has archive_tables => (
        is      => 'ro',
        default => sub {
            return {
                'events'                    => #table name REQUIRED
                {
                    'fields'          => '*', #fields names as in SELECT statment
                    'timestamp_field' => 'receiver_ts', #timestamp field
                },

                'anomaly_history'           => #table name
                {
                    'fields'          => '*', #fields names as in SELECT statment
                    'timestamp_field' => 'end_ts', #timestamp field
                },
                'prf_1hour'                 => #table name
                {
                    'fields'          => '*', #fields names as in SELECT statment
                    'timestamp_field' => 'ts', #timestamp field
                },
                'prf_1min'                  => #table name
                {
                    'fields'          => '*', #fields names as in SELECT statment
                    'timestamp_field' => 'ts', #timestamp field
                },
                'prf_1sec'                  => #table name
                {
                    'fields'          => '*', #fields names as in SELECT statment
                    'timestamp_field' => 'ts', #timestamp field
                },
                'observer_history_t1'       => #table name
                {
                    'fields'          => '*', #fields names as in SELECT statment
                    'timestamp_field' => 'ts', #timestamp field
                },
                'observer_history_t1_15min' => #table name
                {
                    'fields'          => '*', #fields names as in SELECT statment
                    'timestamp_field' => 'ts', #timestamp field
                },
                'observer_history_t1_15sec' => #table name
                {
                    'fields'          => '*', #fields names as in SELECT statment
                    'timestamp_field' => 'ts', #timestamp field
                },
                'observer_history_t1_1hr'   => #table name
                {
                    'fields'          => '*', #fields names as in SELECT statment
                    'timestamp_field' => 'ts', #timestamp field
                },
                'observer_history_t1_1min'  => #table name
                {
                    'fields'          => '*', #fields names as in SELECT statment
                    'timestamp_field' => 'ts', #timestamp field
                },

            };
        }
    );

sub _build_file_exists {
    my $self = shift;
    $self->filename($self->{archive_dir}.'/'.$self->archive_data->{file_name});
    unless (-f $self->filename) {
        return 0 unless -f $self->filename.'.gz';
        $self->filename($self->filename.'.gz');
        $self->logger->debug("Detected gzipped $self->{filename} ");
        $self->gzipped(1);
    }
    return 1;
}
sub _build_archive_data {
    my $self = shift;
    $self->logger->debug("search in DB for $self->{archive_id}");
    return   $self->DB->getArchiveData($self->{archive_id});
}


sub _clean_tables($) {
    my $self = shift;
    my $arc_id = shift;
    my $dbh = $self->DB->dbh;
    my $tables = $dbh->selectall_arrayref( "select * from archive_tables  where archive_id=".$arc_id,
        { 'Columns' => { } } );
    my $t0 = [ gettimeofday ];
    my $ev_count_total = 0;
    for my $arc_data (@$tables) {
        my $t1 = [ gettimeofday ];
        $self->logger->warn("table $arc_data->{table_name} not found in config, could not clear data " ) && next unless defined $self->archive_tables->{$arc_data->{table_name}};
        my $t_config = $self->archive_tables->{$arc_data->{table_name}};

        my $sql = "delete from  ".$arc_data->{table_name}." where ".$t_config->{timestamp_field}." >= ? and  ".$t_config->{timestamp_field}." < ?";
        $self->logger->debug("About to delete data :$sql with params ( $arc_data->{start_time}, $arc_data->{end_time})");
        my $ev_count = $dbh->do( $sql, undef, ( $arc_data->{start_time}, $arc_data->{end_time}) );
        $ev_count_total += $ev_count;

        $dbh->commit();
        if ($ev_count) {
            # Vacuum events
#            $dbh->{AutoCommit} = 1;
            $dbh->do( "VACUUM ".$arc_data->{table_name} );
            $self->logger->debug( "Events vacuumed" );
#            $dbh->{AutoCommit} = 0;
        }
        $self->logger->debug(
            "<< archive #$arc_id table ".$arc_data->{table_name}." clenup: $ev_count rows deleted  in ".tv_interval($t1)." seconds" );
    }
    $self->logger->debug(
        "#$arc_id clenup: total $ev_count_total rows deleted in  ".tv_interval($t0)." seconds" );

}
sub unload{
    my $self = shift;
    $self->logger->info("Unloading archive #$self->{archive_id}");
    eval {
        die ("Archive with #$self->{archive_id} not fond in DB") unless $self->archive_data;
        die("archive with id $self->{archive_id}  not loaded into DB") unless $self->archive_data->{in_db};
        $self->_clean_tables($self->archive_id);
        $self->DB->markArchiveLoaded($self->archive_id, 0);
    };
    if ($@) {
        $self->logger->error ("Process died :".$@);
    };
    $self->logger->info("Archive loading finished");
}


sub load{
    my $self = shift;
    $self->logger->info("Loading archive #$self->{archive_id}");
    eval {
        die ("Archive with #$self->{archive_id} not fond in DB") unless $self->archive_data;
        die("archive with id $self->{archive_id} already loaded into DB") if $self->archive_data->{in_db};
        die ("File $self->{filename} (.gz) not fond") unless $self->file_exists;
        $self->_clean_tables($self->archive_id);
        $self->logger->info("About to load data from file \"$self->{filename}\"");
        my $psql_connect = " --username=$self->{DB}->{username} --port=$self->{DB}->{port} --host=$self->{DB}->{host}";
        my $command1 = $self->gzipped
            ? "gunzip -c $self->{filename} 2>&1 | PGPASSWORD=$self->{DB}->{password} psql $psql_connect $self->{DB}->{database}  2>&1"
            : "PGPASSWORD=$self->{DB}->{password} psql $psql_connect $self->{DB}->{database}  -f $self->{filename} 2>&1";
        $self->logger->debug("Executing \"$command1\"");
        system $command1;
        if ($? == - 1) {
            die("failed to execute: $!\n");
        }
        elsif ($? & 127) {
            die(sprintf "child died with signal %d, %s coredump\n",
                ($? & 127), ($? & 128) ? 'with' : 'without');
        }
        else {
            $self->logger->debug(sprintf "child exited with value %d\n", $? >> 8);
            $self->DB->markArchiveLoaded($self->archive_id, 1);
        }
    };
    if ($@) {
        $self->logger->error ("Exception:".$@);
    };
    $self->logger->info("Archive loading finished");
}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
