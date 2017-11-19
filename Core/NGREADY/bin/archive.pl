#!/usr/bin/perl -w

use strict;
use warnings;
use feature qw(say switch);
use DBI qw(:sql_types);
use Config::General;
use Sys::Syslog qw(:DEFAULT setlogsock);
use Getopt::Long;
use Cwd;
use Time::Local;
use POSIX qw/strftime/;
use Config::Crontab;
use Data::Dumper;
use IPC::Run qw(run timeout);
use Time::HiRes qw (gettimeofday tv_interval);
use File::Path qw(make_path);
use Emsgd qw(diag);
use NGNMS::Log4;
use Log::Dispatch::Syslog;
# Syslog defines
use constant LOG_EMERG => (0, 'emerg');
use constant LOG_ALERT => (1, 'alert');
use constant LOG_CRIT => (2, 'crit');
use constant LOG_ERR => (3, 'err');
use constant LOG_WARNING => (4, 'warning');
use constant LOG_NOTICE => (5, 'notice');
use constant LOG_INFO => (6, 'info');
use constant LOG_DEBUG => (7, 'debug');
use constant LOG_USER => scalar 'user';

#TODO create archive record even if 0 records archived, cause sql-file created
#TODO add preview of 'archive_tables' table for archive

# Paths
#my $_crontab = "/usr/bin/crontab";

# ------------------------------------------------------------------------------
# DB Version !!!!!!!!! IMPORTANT FOR ABILITY TO PROCESS OLD ARCHIVES
# ------------------------------------------------------------------------------
use constant DB_VERSION => 34000;# x.xx.xx


my $logger = NGNMS::Log4->new()->get_new_category_logger('archive');


# ------------------------------------------------------------------------------
# Queries constants
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Main section
# ------------------------------------------------------------------------------
my DBI $dbh;
my ( $sth, %opt);

# Get command-line options
GetOptions(\%opt, qw(unload=i load=i dump l:s u:s w:s d:s p:s v:1));

my $feldsInQuestion = '*';
my $tableInQuestion = '';
my $timestampField = 'receiver_ts';
my $arcive_tables = {
    'events'                    => #table name REQUIRED
    {
        'fields'          => '*', #fields names as in SELECT statment
        'timestamp_field' => 'receiver_ts', #timestamp field
    },
# DO NOT ARCHIVE LONG INTERVALS SO WE ALLWAYS HAVE SOME HISTORY DATA
#    'prf_1hour'                 => #table name
#    {
#        'fields'          => '*', #fields names as in SELECT statment
#        'timestamp_field' => 'ts', #timestamp field
#    },
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
# DO NOT ARCHIVE LONG INTERVALS SO WE ALLWAYS HAVE SOME HISTORY DATA
#    'observer_history_t1_1hr'   => #table name
#    {
#        'fields'          => '*', #fields names as in SELECT statment
#        'timestamp_field' => 'ts', #timestamp field
#    },
    'observer_history_t1_1min'  => #table name
    {
        'fields'          => '*', #fields names as in SELECT statment
        'timestamp_field' => 'ts', #timestamp field
    },

};

my $qGetConf = "SELECT arc_expire, arc_delete, arc_period, arc_enable, arc_path, log_syslog, log_level, arc_gzip FROM archive_conf LIMIT 1";

my $qGetEndTime = "SELECT MAX(end_time) FROM archives";
my $qGetArchives = "SELECT file_name FROM archives WHERE end_time < ?";
my $qInsArchive = "INSERT INTO archives (archive_id,start_time, end_time, file_name, in_db) VALUES (?,?, ?, ?, false)";
my $qInsArchiveTables = "INSERT into archive_tables(archive_id,table_name,start_time,end_time,records_count,microsecounds) values (?,?,?,?,?,?)";
my $qDelArchives = "DELETE FROM archives WHERE end_time < ?";
my $updatePeriodic = "UPDATE archive_conf SET  arc_period = ?";



# ------------------------------------------------------------------------------
# Options
# ------------------------------------------------------------------------------
# Connection settings
my $_DBName = $ENV{NGNMS_DB} || 'ngnms';
my $_DBPort = $ENV{NGNMS_DB_PORT} || '5432';
my $_DBHost = $ENV{NGNMS_DB_HOST} || 'localhost';
my $_DBUser = $ENV{NGNMS_DB_USER} || 'ngnms';
my $_DBPass = $ENV{NGNMS_DB_PASSWORD} || 'ngnms';

# Archive settings
my $_ArcTimeout = 86400 * 180;
my $_ArcDelTimeout = 86400 * 365;
my $_ArcPeriod = '0 0 */1 * *';
my $_ArcGzip = 0;
my $_ArcPath = ($ENV{NGNMS_DATA} || '.') . '/archive';
if (!-d $_ArcPath) {
    $logger->info("Creating archive path $_ArcPath");
    make_path $_ArcPath or die "Failed to create path: $_ArcPath";

}
my $_ArcSettings = ($ENV{NGNMS_CONFIG} || '.') . '/configs/archive-time.conf';

# Logging settings
my $_LogSyslog = 1;
my $_LogLevel = 0;

# Other settings
#my $ConfigFile = $ENV{NGNMS_HOME}.'/configs/archive.conf';



&usage if (!defined($opt{start}) && !defined($opt{stop}) && !defined($opt{dump}) && !defined($opt{unload}) && !defined($opt{load}));
&usage if ((defined($opt{start}) && defined($opt{stop})) || (defined($opt{start}) && defined($opt{dump})) || (defined($opt{stop}) && defined($opt{dump})));

eval {
    # Load config
    &loadConfig;

    # Init log
    $logger->info("Starting archiver");
    &logOptions;

    # Perform dump
    &doDump if (defined($opt{dump}));

    &doUnLoad if (defined($opt{unload}));
    &doLoad if (defined($opt{load}));

    # Schedule
    #    &doStart if ( defined($opt{start})  );

    # Unschedule
    #    &doStop if ( defined($opt{stop})   );

    # Close log
    $logger->info("Finished successfully");
};

if ($@) {
    $logger->error("Execution aborted due to: $@\n");
}

# ------------------------------------------------------------------------------
# Crontab schedule
# ------------------------------------------------------------------------------
#@deprecated
sub doStart {
    #TODO move scheduler to shceduler.pl so all scheduling will be on one place
    my ($sc, $c, $p);

    $logger->info(">> Scheduling crontab");

    #todo remove old in-db scheduling format
    # Get period from command line if any
    #    $_ArcPeriod = $opt{start} if ( $opt{start} ne '' );

    ## Change access to DB
    my $file = $ENV{NGNMS_HOME} . "/bin/archive_run.sh";

    open (IN, $file) || die "Cannot open file " . $file . " for read";
    my @lines0 = <IN>;
    close IN;

    open (OUT, ">", $file) || die "Cannot open file " . $file . " for write";
    foreach my $line (@lines0) {
        $line = "HOST='$_DBHost'\n" if $line =~ m/^HOST/;
        $line = "DB='$_DBName'\n" if $line =~ m/^DB/;
        $line = "USER='$_DBUser'\n" if $line =~ m/^USER/;
        $line = "PASSWD='$_DBPass'\n" if $line =~ m/^PASSWD/;
        print OUT $line;
    }
    close OUT;
    # Parse and validate period
    chomp $_ArcPeriod;
    #todo remove old in-db scheduling format
    #    if ($_ArcPeriod =~ /^(\d+)(d|h|m)$/) {
    ##        diag "old format";
    #        #OLD or manual format
    #        $c = $1;
    #        $p = $2;
    #
    #        # Prepare line for cron
    #        $sc = "";
    #        $sc .= "*/$c  *     *     *     *  " if ( $p eq 'm' );
    #        $sc .= "0     */$c  *     *     *  " if ( $p eq 'h' );
    #        $sc .= "0     0     */$c  *     *  " if ( $p eq 'd' );
    #    } else {
    #        unless ($_ArcPeriod =~ /^[\s\d\*\-\/]+$/) {
    ##            diag $_ArcPeriod;
    #            $logger->warn("Wrong period-- [$_ArcPeriod]" );
    #            &usage;
    #        }
    #        $sc = $_ArcPeriod;
    #    }

    unless ($_ArcPeriod =~ /^[\s\d\*\-\/]+$/) {
        #            diag $_ArcPeriod;
        $logger->warn("Wrong period-- [$_ArcPeriod]");
        &usage;
    }
    $sc = $_ArcPeriod;

    $sc =~ s/\s+/ /g;
    # Remove old schedule
    &doStop;

    ## Open crontab for user ngnms
    my $ct = new Config::Crontab(-owner => 'ngnms');
    ## read crontab
    $ct->read;

    ## create an array of crontab objects
    my @lines = (new Config::Crontab::Comment(-data => '## archive'),
        new Config::Crontab::Event(-data => $sc . ' /home/ngnms/NGREADY/bin/archive_run.sh'));

    ## create a block object via lines attribute
    my $newblock = new Config::Crontab::Block(-lines => \@lines);

    ## add this block to crontab file
    $ct->last($newblock);
    ## write out crontab file
    $ct->write;
    #todo remove to-database periodic updates???, we manage it only from web
    #    &dbConnect;
    #    $logger->debug("SQL: [$updatePeriodic ]" );
    #    $dbh->do( $updatePeriodic,  undef, ( $sc ) );
    #    &dbDisconnect;
    $logger->info("<< Scheduling complete");
}
#@deprecated
sub doStop {
    ## Open crontab for user ngnms
    my $ct = new Config::Crontab(-owner => 'ngnms');
    $ct->read;
    my $oldblock = $ct->block($ct->select(-type => "comment", -data_re => 'archive'));

    if (defined $oldblock) {
        ## remove this block from the crontab
        $ct->remove($oldblock);
        ## write changes in crontab
        $ct->write;
    }

}







sub logOptions {
    $logger->debug("_DBName         = $_DBName");
    $logger->debug("_DBPort         = $_DBPort");
    $logger->debug("_DBHost         = $_DBHost");
    $logger->debug("_DBUser         = ****");
    $logger->debug("_DBPass         = ****");
    $logger->debug("_ArcGzip        = $_ArcGzip");
    $logger->debug("_ArcPath        = $_ArcPath");
    $logger->debug("_ArcSettings    = $_ArcSettings");
    $logger->debug("_ArcTimeout     = $_ArcTimeout");
    $logger->debug("_ArcDelTimeout  = $_ArcDelTimeout");
    $logger->debug("_ArcPeriod      = $_ArcPeriod");
}

# ------------------------------------------------------------------------------
# Load config
# ------------------------------------------------------------------------------
sub loadConfig {
    #conf is not used anymore
    #  my $config = new Config::General(
    #		  -file => $ConfigFile,
    #		  -AllowMultiOptions => 'no'
    #	  );
    #  my %conf = $config->getall;

    # Connection settings
    $_DBName = $opt{d} if defined $opt{d};
    $_DBPort = $opt{p} if defined $opt{p};
    $_DBHost = $opt{l} if defined $opt{l};
    $_DBUser = $opt{u} if defined $opt{u};
    $_DBPass = $opt{w} if defined $opt{w};

    &dbConnect;

    $logger->debug("SQL: [qGetConf ]");
    $sth = $dbh->prepare($qGetConf);
    $sth->execute();
    my $row = $sth->fetchrow_hashref;

    $sth->finish();
    # Archive settings
    $_ArcGzip = $row->{arc_gzip} || $_ArcGzip;

    # Archive paths
    $_ArcPath = $row->{arc_path} || $_ArcPath;
    # Fix paths
    $_ArcPath = $ENV{NGNMS_DATA} . "/" . $_ArcPath unless ($_ArcPath =~ /^\//);
    ##  $_ArcSettings   =	$conf{'arc_setting'}   if( defined $conf{'arc_setting'} );

    # Logging settings

    #    $_LogSyslog = $row->{log_syslog} || $_LogSyslog;
    #    $_LogLevel =  $row->{log_level} || $_LogLevel;
    #    $_LogLevel = $opt{v}  if defined $opt{v};

    #  $_ArcSettings   = $ENV{NGNMS_HOME}."/".$_ArcSettings unless( $_ArcSettings =~ /^\// );

    # Load timings

    $_ArcTimeout = $row->{arc_expire} || $_ArcTimeout;
    $_ArcDelTimeout = $row->{arc_delete} || $_ArcDelTimeout;

    # Transform to seconds
    $_ArcTimeout = &ti2sec($_ArcTimeout);
    $_ArcDelTimeout = &ti2sec($_ArcDelTimeout);

    if (!defined($opt{start}) || $opt{start} eq '') {
        $_ArcPeriod = $row->{arc_period} || $_ArcPeriod;
    }

    &dbDisconnect;
}



# ------------------------------------------------------------------------------
# TimeInterval to seconds converting
# ------------------------------------------------------------------------------
sub ti2sec {
    my $str = shift;
    my @tokens = split(/\s+/, $str);
    my ($d, $h, $m, $k, $c, $t);
    $d = 0;
    $h = 0;
    $m = 0;
    $k = '';
    $c = 0;

    # Analyze tokens
    foreach $t (@tokens) {
        if ($t =~ /^(\d+)(d|h|m)$/) {
            $c = $1;
            $k = $2;
            die "Number cannot be 0 in [$str] configuration file\n" if ($c == 0);
            if ($k eq 'd') {
                die "Duplicate 'd'ay token in config line [$str]\n" if ($d > 0);
                $d = $c;
            }
            elsif ($k eq 'h') {
                die "Duplicate 'h'our token in config line [$str]\n" if ($h > 0);
                $h = $c;
            }
            else {
                die "Duplicate 'm'inute token in config line [$str]\n" if ($m > 0);
                $m = $c;
            }
        }
        else {
            die "Wrong token [$t] in line [$str] while reading configuration\n";
        }
    }
    my $res = 86400 * $d + 3600 * $h + 60 * $m;

    return 86400 * $d + 3600 * $h + 60 * $m;
}


# ------------------------------------------------------------------------------
# Dump operation
# ------------------------------------------------------------------------------
sub doDump {
    my ( $start_time, $end_time, @row, $fileName, $fromTime, $ev_count);

    &dbConnect;

    eval
    {

        $logger->debug("SQL: [$qGetEndTime]");
        @row = $dbh->selectrow_array($qGetEndTime);
        $fromTime = $row[0] ? $row[0] : "-infinity";
        my $time_shift = &timeshiftCalculate;
        my $time_delete = &timedeleteCalculate;

        # Generate archive filename & open file
        chomp($fileName = `date "+%Y%m%d-%H%M"`);
        $fileName .= ".sql";
        $logger->info("Dumping events to $_ArcPath/$fileName");
        open(DUMP, ">$_ArcPath/$fileName") || die "cannot create dump file $_ArcPath/$fileName : $!";
        my $ev_total_count = 0;
        my $table_start_stop = {};

        for my $table (keys %$arcive_tables) {
            my $t0 = [ gettimeofday ];

            my $exists = $dbh->selectrow_array(
                "select EXISTS(
                            select 1 from
                            information_schema.tables
                            where table_name = '$table'
                        );"
            );

            $logger->info("TABLE  $table SKIPPED cause it not exists") && next unless $exists;


            #set variable for table we are archiving (DBI->prepare dont allow param as table name)

            $feldsInQuestion = $arcive_tables->{$table}->{fields};
            $timestampField = $arcive_tables->{$table}->{timestamp_field};
            $tableInQuestion = $dbh->quote_identifier($table);

            my $qGetEvents = "SELECT $feldsInQuestion FROM $tableInQuestion WHERE $timestampField >= ? AND $timestampField <  ? ORDER BY $timestampField ASC";
            my $qGetTimes = "SELECT MIN($timestampField), MAX($timestampField) FROM $tableInQuestion WHERE ($timestampField >= ? AND $timestampField <  ?)";

            my $qGetEvtCount = "SELECT COUNT(*) FROM $tableInQuestion WHERE $timestampField >= ? AND $timestampField <  ?";
            my $qDelEvents = "DELETE FROM $tableInQuestion WHERE $timestampField >= ? AND $timestampField < ?";
            my $qVacuumEvt = "VACUUM $tableInQuestion";

            $logger->debug("TABLE: [$tableInQuestion] with fields [$feldsInQuestion] by timestamp field [$timestampField]");
            # Get most recent end_time


            # Get start_time and end_time
            $logger->debug("SQL: [$qGetTimes], [$fromTime, $time_shift, for \"$_ArcTimeout second\"]");
            $sth = $dbh->prepare($qGetTimes);
            $sth->execute(($fromTime, $time_shift));
            @row = $sth->fetchrow_array;
            $start_time = $row[0];
            $end_time = $row[1];
            if (!defined $start_time || !defined $end_time) {
                $logger->debug("Nothing to dump for table $table [$fromTime, $time_shift, for \"$_ArcTimeout second\"]");
                next;
            }
            $table_start_stop->{$table} = { start => $start_time, end => $end_time, count => 0 };

            # Check whether there are events to archive
            $logger->debug("Checking for number of events to archive");
            $logger->debug("SQL: [$qGetEvtCount], [$start_time , $end_time]");
            $sth = $dbh->prepare($qGetEvtCount);

            $sth->execute($start_time, $end_time);
            @row = $sth->fetchrow_array;
            $ev_count = $row[0];
            $ev_total_count += $ev_count;

            # Do not dump if nothing to dump
            if ($ev_count eq '0') {
                $logger->info("Nothing to dump from table '$table'");
#                next;
                # add empty archives too so we have info in database
                # and archive perf tables if no events
                # and run vacuum on tables
            }
            else {
                $table_start_stop->{$table}->{count} = $ev_count;
                $logger->info("Dump started  for $table ($ev_count records)");

                # --- Header start
                print DUMP '-- Version  ' . DB_VERSION . "\n";
                print DUMP<<EOF;
-- Disable triggers
--UPDATE "pg_class" SET "reltriggers" = 0 WHERE "relname" = 'events';
COPY $tableInQuestion FROM stdin  WITH (DELIMITER ';' , FORMAT CSV , HEADER , QUOTE  '\"' );
EOF

                # --- Header end


                # Dump events to file
                $logger->debug("SQL: [$qGetEvents], [$start_time, $end_time, for \"$_ArcTimeout second\"]");
                $qGetEvents =~ s/\?/'$start_time'/;
                $qGetEvents =~ s/\?/'$end_time'/;
                my $sql = " copy ($qGetEvents) TO STDOUT  WITH (DELIMITER ';' , FORMAT CSV , HEADER , QUOTE  '\"' ,FORCE_QUOTE *)";
                $dbh->do($sql);
                #       Emsgd::pp($sql);
                my $copy_data;
                while ($dbh->pg_getcopydata($copy_data) >= 0) {
                    print DUMP $copy_data;
                }
                #Emsgd::pp(@copy_data[1]);
                #      while( @row = $sth->fetchrow_array ) {
                #        print DUMP join( "\t", @row )."\n";
                #      }
                # --- Footer start
                print DUMP<<EOF;
\\.
-- Enable triggers
--UPDATE pg_class SET reltriggers = (SELECT count(*) FROM pg_trigger where pg_class.oid = tgrelid) WHERE relname = 'events';
EOF
                # --- Footer end

                $logger->info("Dump complete for table $table");
                $table_start_stop->{$table}->{elapsed} = tv_interval ($t0);

            } # Dump section



            # Clear archived records from  table
            $logger->debug("SQL: [$qDelEvents], [$start_time, \"$end_time for \"$_ArcTimeout secondd\"]");
            $dbh->do($qDelEvents, undef, ($start_time, $end_time));

            $logger->debug("Events purged");

            # Finally commit transaction
#            $dbh->commit;

            # Vacuum events
#            $dbh->{AutoCommit} = 1;
            $logger->debug("Start table $table vacuuming");
            $dbh->do($qVacuumEvt);
            $logger->debug("table $table vacuumed");
#            $dbh->{AutoCommit} = 0;
        }
        # Add archive record to table archives
        if ($ev_total_count) {
            $start_time = $table_start_stop->{events}->{start};
            $end_time = $table_start_stop->{events}->{end};
            $logger->debug("SQL: [$qInsArchive], [$start_time, $end_time, $fileName]");
            my $next_id = $dbh->selectrow_array("select nextval('archives_archive_id_seq')");
            $sth = $dbh->prepare($qInsArchive);
            $sth->execute(($next_id, $start_time, $end_time, $fileName));
#            $dbh->commit;
            $logger->debug("Archive record added to DB");
            $sth = $dbh->prepare($qInsArchiveTables);
            for my $table (keys %$table_start_stop) {
                $logger->debug("SQL: [$qInsArchiveTables], [$next_id, $table,$start_time, $end_time, $fileName]");
                $sth->execute((
                    $next_id,
                    $table,
                    $table_start_stop->{$table}->{start},
                    $table_start_stop->{$table}->{end},
                    $table_start_stop->{$table}->{count},
                    $table_start_stop->{$table}->{elapsed}
                )
                );
            }
#            $dbh->commit;
        }

        $logger->debug(">> Deleting old archive files");

        # Delete old archive files
        $logger->debug("SQL: [$qGetArchives], [$time_delete, $_ArcDelTimeout]");
        $sth = $dbh->prepare($qGetArchives);
        $sth->execute($time_delete);
#        diag($time_delete);
        while (@row = $sth->fetchrow_array) {
            unlink "$_ArcPath/$row[0]";
            $logger->debug("Archive file $_ArcPath/$row[0] deleted");
        }

        # Delete archive records
        $logger->debug("SQL: [$qDelArchives], [\"$_ArcDelTimeout second\"]");
        $sth = $dbh->prepare($qDelArchives);
        $sth->execute($time_delete);
#        $dbh->commit;

        $logger->debug("Old archive files deleted");

        close DUMP || die "cannot close dump file $fileName : $!";

        # Gzip if needed
        if ($_ArcGzip) {
            $logger->debug("Gzipping dump $_ArcPath/$fileName");
            `gzip -9 $_ArcPath/$fileName`;
            $fileName .= ".gz";
            $logger->debug("Gzipping complete");
        }
    };

    if ($@) {
#        $dbh->rollback;
        $logger->logdie("Transaction aborted because $@");
    }

    &dbDisconnect;
}

sub _clean_tables($) {
    my $arc_id = shift;
    my $tables = $dbh->selectall_arrayref("select * from archive_tables  where archive_id=" . $arc_id,
        { 'Columns' => {} });
    my $t0 = [ gettimeofday ];
    my $ev_count_total = 0;
    for my $arc_data (@$tables) {
        my $t1 = [ gettimeofday ];
        $logger->error("table " . $arc_data->{table_name} . " not found in config, could not clear data ") && next unless defined $arcive_tables->{$arc_data->{table_name}};
        my $t_config = $arcive_tables->{$arc_data->{table_name}};

        my $sql = "delete from  " . $arc_data->{table_name} . " where " . $t_config->{timestamp_field} . " >= ? and  " . $t_config->{timestamp_field} . " < ?";
        $logger->debug("About to delete data :$sql with params ( $arc_data->{start_time}, $arc_data->{end_time})");
        my $ev_count = $dbh->do($sql, undef, ($arc_data->{start_time}, $arc_data->{end_time}));
        $ev_count_total += $ev_count;

#        $dbh->commit();
        if ($ev_count) {
            # Vacuum events
#            $dbh->{AutoCommit} = 1;
            $dbh->do("VACUUM " . $arc_data->{table_name});
            $logger->debug("Events vacuumed");
#            $dbh->{AutoCommit} = 0;
        }
        $logger->debug(
            "<< archive #$arc_id table " . $arc_data->{table_name} . " clenup: $ev_count rows deleted  in " . tv_interval($t1) . " seconds");
    }
    $logger->debug(
        "#$arc_id clenup: total $ev_count_total rows deleted in  " . tv_interval($t0) . " seconds");

}
sub doLoad {
    say "Do load";
    my ($start_time, $end_time, $ev_count, $arc_id, $archive, @cmd1, @cmd2, $out );
    $arc_id = $opt{load};
    $| = 1;
    &dbConnect;
    eval {

        my $t0 = [ gettimeofday ];
        $archive = $dbh->selectrow_hashref("select * from archives where archive_id=" . $arc_id);
        #        Emsgd::diag($archive);
        die("archive with id $arc_id not found") unless defined $archive;
        die("archive with id $arc_id already loaded into DB") if $archive->{in_db};
        # ------------------ cleanup before load to avoid PK violation ------------------------
        _clean_tables($arc_id);
        # ------------------ try to find gzipped first (for old archives created via GUI but gzipeed manually)  ------------------
        my $gzipped = 0;
        my $filename = $archive->{file_name};
        if (-e "$_ArcPath/$filename" . '.gz') {
            $gzipped = 1;
            $filename .= '.gz';
        }
        elsif (-e "$_ArcPath/$filename" && ($filename =~ /\.gz$/)) {
            $gzipped = 1;
        }
        $filename = "$_ArcPath/$filename";
        if ($gzipped) {
            @cmd1 = ('gunzip', '-c', $filename);
        }
        else {
            @cmd1 = ('cat', $filename);
        }
        $ENV{PGPASSWORD} = $_DBPass;
        @cmd2 = ('/usr/bin/psql', '-h', $_DBHost, '-p', $_DBPort, '-U', $_DBUser, '-d', $_DBName);
        run   \@cmd1, '|', \@cmd2, \$out, '2>&1';
        $ENV{PGPASSWORD} = undef;
        die "system command failed: $out" if $out ne '';
        $dbh->do("update archives set in_db=true where archive_id=" . $arc_id) or die $dbh->errstr;
        $logger->debug("<< archive #$arc_id loaded in " . tv_interval($t0) . " sec");
#        $dbh->commit();
    };
    if ($@) {
        $dbh->rollback;
        $logger->logdie("Transaction aborted because $@");
    }

    &dbDisconnect;
}

sub doUnLoad {
    say "Do Unload";
    my ($ev_count, $arc_id, $archive );
    $arc_id = $opt{unload};

    &dbConnect;
    eval {
        my $t0 = [ gettimeofday ];
        $ev_count = 0;
        $archive = $dbh->selectrow_hashref("select * from archives where archive_id=" . $arc_id);
        #        Emsgd::diag($archive);
        die("archive with id $arc_id not found") unless defined $archive;
        die("archive with id $arc_id not loaded into DB") unless $archive->{in_db};
        _clean_tables($arc_id);
        $dbh->do("update archives set in_db=false where archive_id=" . $arc_id);
#        $dbh->commit();
        $logger->debug("<< archive #$arc_id unloaded, $ev_count rows deleted in " . tv_interval($t0) . " sec");
    };
    if ($@) {
        $dbh->rollback;
        $logger->logdie("Transaction aborted because $@");
    }

    &dbDisconnect;

}
#=for debug
#
#$delete from  events where receiver_ts >=? and  receiver_ts <= ? = {
#                                                                     'start_time' => '2016-07-14 22:03:50.686886+00',
#                                                                     'table_name' => 'events',
#                                                                     'end_time' => '2016-07-22 07:48:49.956489+00',
#                                                                     'archive_id' => 1049,
#                                                                     'id' => 16,
#                                                                     'microsecounds' => '0.19725',
#                                                                     'records_count' => 59112
#                                                                   };
#=cut

# ------------------------------------------------------------------------------
# Database utilities
# ------------------------------------------------------------------------------
sub dbConnect {
    my $dsn = "dbi:Pg:dbname=$_DBName" . ($_DBHost ne '' ? ";host=$_DBHost" : "") . ($_DBPort ne '' ? ";port=$_DBPort" : "");
    $logger->debug("DBI connect('$dsn','$_DBUser',...)");

    $dbh = DBI->connect($dsn, $_DBUser, $_DBPass) || die $DBI::errstr;
    $dbh->{AutoCommit} = 1;  # enable transactions
    $dbh->{RaiseError} = 1;
}

sub dbDisconnect {
    $dbh->disconnect;
}

sub timeshiftCalculate {
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    my $back_time = timelocal($sec, $min, $hour, $mday, $mon, $year) - $_ArcTimeout;
    my @time = localtime($back_time);
    my $oops = strftime '%Y-%m-%d %H:%M:%S', @time;

    return $oops;
}


sub timedeleteCalculate {
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    my $back_time = timelocal($sec, $min, $hour, $mday, $mon, $year) - $_ArcDelTimeout;
    my @time = localtime($back_time);
    my $oops = strftime '%Y-%m-%d %H:%M:%S', @time;
#    my @t = localtime();
#    diag(\@t);
#    diag($oops);
    return $oops;
}
# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------
sub usage {
    print <<EOF;
Usage: $0 [OPTION...] {--start [N{d|h|m}]|--stop|--dump}
  OPTIONS:
      -d              database name
      -l              database host
      -p              database port
      -u              database user
      -w              database password
      -v              verbose level 0-3

  --dump              Perfom dump.
  --load={ARCHIVE_ID}   Load data   by archives table id  into DB
  --unload={ARCHIVE_ID} Delete data by archives table id  into DB



EOF
    exit;
}



