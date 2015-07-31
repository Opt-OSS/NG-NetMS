#!/usr/bin/perl -w

use strict;
use DBI qw(:sql_types);
use Config::General;
use Sys::Syslog qw(:DEFAULT setlogsock);
use Getopt::Long;
use Cwd;
use Time::Local;
use POSIX qw/strftime/;
use Config::Crontab;
use Data::Dumper;

# Syslog defines
use constant LOG_EMERG    => (0, 'emerg');
use constant LOG_ALERT    => (1, 'alert');
use constant LOG_CRIT     => (2, 'crit');
use constant LOG_ERR      => (3, 'err');
use constant LOG_WARNING  => (4, 'warning');
use constant LOG_NOTICE   => (5, 'notice');
use constant LOG_INFO     => (6, 'info');
use constant LOG_DEBUG    => (7, 'debug');
use constant LOG_USER     => scalar 'user';


# Paths
my $_crontab  = "/usr/bin/crontab";

# ------------------------------------------------------------------------------
# Queries constants
# ------------------------------------------------------------------------------
my $qGetTimes     = "SELECT MIN(receiver_ts), MAX(receiver_ts) FROM events WHERE (receiver_ts >= ? AND receiver_ts <  ?)";
my $qGetEvents    = "SELECT event_id, origin_ts, receiver_ts, origin, origin_id, facility, code, descr, priority, severity, raw_event FROM events WHERE receiver_ts >= ? AND receiver_ts <  ? ORDER BY receiver_ts ASC";
my $qGetEvtCount  = "SELECT COUNT(*) FROM events WHERE receiver_ts >= ? AND receiver_ts <  ?";
my $qDelEvents    = "DELETE FROM events WHERE receiver_ts >= ? AND receiver_ts < ?";
my $qVacuumEvt    = "VACUUM events";

my $qGetEndTime   = "SELECT MAX(end_time) FROM archives";
my $qGetArchives  = "SELECT file_name FROM archives WHERE end_time < ?";
my $qInsArchive   = "INSERT INTO archives (start_time, end_time, file_name, in_db) VALUES (?, ?, ?, false)";
my $qDelArchives  = "DELETE FROM archives WHERE end_time < ?";



# ------------------------------------------------------------------------------
# Options
# ------------------------------------------------------------------------------
# Connection settings
my $_DBName         = 'ngnms';
my $_DBPort         = '5432';
my $_DBHost         = 'localhost';
my $_DBUser         = 'ngnms';
my $_DBPass         = '';

# Archive settings
my $_ArcTimeout     = 86400*180;
my $_ArcDelTimeout  = 86400*365;
my $_ArcPeriod      = 86400;
my $_ArcGzip        = 0;
my $_ArcPath		= $ENV{NGNMS_HOME}.'/archive';
my $_ArcSettings    = $ENV{NGNMS_HOME}.'/conf/archive-time.conf';

# Logging settings
my $_LogSyslog      = 1;
my $_LogLevel       = 6;

# Other settings
my $ConfigFile      = $ENV{NGNMS_HOME}.'/conf/archive.conf';

# ------------------------------------------------------------------------------
# Main section
# ------------------------------------------------------------------------------
my ($dbh, $sth, %opt);

# Get command-line options
GetOptions( \%opt, qw(start:s stop dump l:s u:s w:s d:s p:s ) );

&usage if( !defined($opt{start}) && !defined($opt{stop}) && !defined($opt{dump}) );
&usage if( (defined($opt{start})&&defined($opt{stop})) || (defined($opt{start})&&defined($opt{dump})) || (defined($opt{stop})&&defined($opt{dump})) );

eval {
  # Load config
  &loadConfig;
  
  # Init log
  &logOpen;
  &logMsg( LOG_INFO, "Starting archiver" );
  &logOptions;

  # Perform dump
  &doDump   if( defined($opt{dump})   );

  # Schedule
  &doStart  if( defined($opt{start})  );

  # Unschedule
  &doStop   if( defined($opt{stop})   );

  # Close log
  &logMsg( LOG_INFO, "Finished successfully" );
  &logClose;
};

if ($@) {
  warn "Execution aborted due to: $@\n";
  logMsg( LOG_CRIT, "Execution aborted due to: $@\n" );
  &logClose;
}

# ------------------------------------------------------------------------------
# Crontab schedule
# ------------------------------------------------------------------------------
sub doStart {
  my ($sc,$c,$p);

  logMsg( LOG_INFO, ">> Scheduling crontab" );

  # Get period from command line if any
  $_ArcPeriod = $opt{start} if( $opt{start} ne '' );

## Change access to DB
	my $file = "archive_run.sh"; 
	
	open (IN, $file) || die "Cannot open file ".$file." for read";       
			my @lines0=<IN>;    
	close IN;  
  
	open (OUT, ">", $file) || die "Cannot open file ".$file." for write";  
	foreach my $line (@lines0)  
	{    
		$line="HOST='$_DBHost'\n" if $line =~ m/^HOST/;
		$line="DB='$_DBName'\n" if $line =~ m/^DB/;
		$line="USER='$_DBUser'\n" if $line =~ m/^USER/;
		$line="PASSWD='$_DBPass'\n" if $line =~ m/^PASSWD/;
		print OUT $line;    
	}    
	close OUT;
  # Parse and validate period
  chomp $_ArcPeriod;
  unless( $_ArcPeriod =~ /^(\d+)(d|h|m)$/ ) {
    logMsg( LOG_WARNING, "Wrong period [$_ArcPeriod]" );
    &usage;
  }
  $c = $1; $p = $2;

  # Prepare line for cron
  $sc  = "";
  $sc .= "*/$c  *     *     *     *  " if( $p eq 'm' );
  $sc .= "0     */$c  *     *     *  " if( $p eq 'h' );
  $sc .= "0     0     */$c  *     *  " if( $p eq 'd' );

  # Remove old schedule
  &doStop;
 
    ## Open crontab for user ngnms
    my $ct = new Config::Crontab( -owner => 'ngnms' );
## read crontab    
    $ct->read;

     ## create an array of crontab objects
    my @lines = ( new Config::Crontab::Comment(-data => '## archive'),
                 new Config::Crontab::Event(-data => $sc.' /home/ngnms/NGREADY/bin/archive_run.sh') );

    ## create a block object via lines attribute
    my $newblock = new Config::Crontab::Block( -lines => \@lines );

	## add this block to crontab file
	$ct->last($newblock);
	## write out crontab file
	$ct->write;

  logMsg( LOG_INFO, "<< Scheduling complete" );
}

sub doStop {
	## Open crontab for user ngnms
    my $ct = new Config::Crontab( -owner => 'ngnms' );
    $ct->read;
    my $oldblock = $ct->block($ct->select(-type => "comment",-data_re => 'archive'));
    
    if(defined $oldblock)
	{
		## remove this block from the crontab
		$ct->remove($oldblock);
		## write changes in crontab
		$ct->write;
	}
    
}

# ------------------------------------------------------------------------------
# Syslog utils
# ------------------------------------------------------------------------------
sub logOpen {
  if( $_LogSyslog ) {
    setlogsock('unix');
    openlog( 'NGNMS Archiver', 'pid', LOG_USER );
  }
}

sub logClose {
  if( $_LogSyslog ) {
    closelog;
  }
}

sub logMsg {
  my $l   = shift;
  my $ls  = shift;
  my $msg = shift;

  if( $_LogSyslog && $l <= $_LogLevel ) {
    syslog( $ls, "[$ls] $msg" );
  }
}

sub logOptions {
  logMsg( LOG_DEBUG, "_DBName         = $_DBName" );
  logMsg( LOG_DEBUG, "_DBPort         = $_DBPort" );
  logMsg( LOG_DEBUG, "_DBHost         = $_DBHost" );
  logMsg( LOG_DEBUG, "_DBUser         = $_DBUser" );
  logMsg( LOG_DEBUG, "_DBPass         = $_DBPass" );
  logMsg( LOG_DEBUG, "_ArcGzip        = $_ArcGzip" );
  logMsg( LOG_DEBUG, "_ArcPath        = $_ArcPath" );
  logMsg( LOG_DEBUG, "_ArcSettings    = $_ArcSettings" );
  logMsg( LOG_DEBUG, "_ArcTimeout     = $_ArcTimeout" );
  logMsg( LOG_DEBUG, "_ArcDelTimeout  = $_ArcDelTimeout" );
  logMsg( LOG_DEBUG, "_ArcPeriod      = $_ArcPeriod" );
}

# ------------------------------------------------------------------------------
# Load config
# ------------------------------------------------------------------------------
sub loadConfig {
  my $config = new Config::General(
		  -file => $ConfigFile,
		  -AllowMultiOptions => 'no'
	  );
  my %conf = $config->getall;

  # Connection settings
  $_DBName        = $opt{d}       if( defined $opt{d}    );
  $_DBPort        = $opt{p}       if( defined $opt{p}     );
  $_DBHost        = $opt{l}       if( defined $opt{l}     );
  $_DBUser        = $opt{u}       if( defined $opt{u}     );
  $_DBPass        = $opt{w}       if( defined $opt{w}     );
  
&dbConnect;
  my $qGetConf      = "SELECT arc_expire, arc_delete, arc_period, arc_enable, arc_path, log_syslog, log_level, arc_gzip FROM archive_conf LIMIT 1";
  logMsg( LOG_DEBUG, "SQL: [qGetConf ]" );
      $sth = $dbh->prepare( $qGetConf  );
      $sth->execute( );
      my @row = $sth->fetchrow_array;
      $sth->finish();
  # Archive settings
  $_ArcGzip		    =	$row[8]      if( defined $row[8]    );

  # Archive paths
  $_ArcPath		    =	$row[4]      if( defined $row[4]    );
##  $_ArcSettings   =	$conf{'arc_setting'}   if( defined $conf{'arc_setting'} );

  # Logging settings
  $_LogSyslog     = $row[5]    if( defined $row[5]  );
  $_LogLevel      = $row[6]     if( defined $row[6]   );

  # Fix paths
  $_ArcPath       = $ENV{NGNMS_HOME}."/".$_ArcPath     unless( $_ArcPath =~ /^\// );
#  $_ArcSettings   = $ENV{NGNMS_HOME}."/".$_ArcSettings unless( $_ArcSettings =~ /^\// );

  # Load timings

    $_ArcTimeout    = $row[0]    if( defined $row[0] );
    $_ArcDelTimeout = $row[1]   if( defined $row[1]  );

    # Transform to seconds
    $_ArcTimeout    = &ti2sec( $_ArcTimeout     );
    $_ArcDelTimeout = &ti2sec( $_ArcDelTimeout  );

    if( !defined($opt{start}) || $opt{start} eq '' ) {
      $_ArcPeriod   = $row[2]    if( defined $row[2]  );
   }
   
   &dbDisconnect;
 }



# ------------------------------------------------------------------------------
# TimeInterval to seconds converting
# ------------------------------------------------------------------------------
sub ti2sec {
  my $str    = shift;
  my @tokens = split( /\s+/, $str );
  my ($d,$h,$m,$k,$c,$t);
  $d=0; $h=0; $m=0; $k=''; $c=0;

  # Analyze tokens
  foreach $t (@tokens) {
    if( $t =~ /^(\d+)(d|h|m)$/ ) {
      $c = $1; $k = $2;
      die "Number cannot be 0 in [$str] configuration file\n" if( $c == 0 );
      if( $k eq 'd' ) {
        die "Duplicate 'd'ay token in config line [$str]\n" if( $d > 0 );
        $d = $c;
      } elsif ( $k eq 'h' ) {
        die "Duplicate 'h'our token in config line [$str]\n" if( $h > 0 );
        $h = $c;
      } else {
        die "Duplicate 'm'inute token in config line [$str]\n" if( $m > 0 );
        $m = $c;
      }
    } else {
      die "Wrong token [$t] in line [$str] while reading configuration\n";
    }
  }
  my $res = 86400*$d + 3600*$h + 60*$m;

  return 86400*$d + 3600*$h + 60*$m;
}


# ------------------------------------------------------------------------------
# Dump operation
# ------------------------------------------------------------------------------
sub doDump {
  my ($start_time, $end_time, @row, $fileName, $fromTime, $ev_count);

  &dbConnect;

  eval
  {
    # Get most recent end_time
    logMsg( LOG_DEBUG, "SQL: [$qGetEndTime]" );
    @row = $dbh->selectrow_array( $qGetEndTime );
    $fromTime = $row[0] ? $row[0] : "-infinity";

    # Check whether there are events to archive
    logMsg( LOG_INFO,  ">> Checking for number of events to archive" );
    logMsg( LOG_DEBUG, "SQL: [$qGetEvtCount], [$fromTime, \"$_ArcTimeout second\"]" );
    $sth = $dbh->prepare( $qGetEvtCount );
	my $time_shift = &timeshiftCalculate;
	my $time_delete = &timedeleteCalculate;
	
    $sth->execute( $fromTime, $time_shift );
    @row = $sth->fetchrow_array;
		$ev_count = $row[0];
		
    logMsg( LOG_INFO,  "<< Found $ev_count event(s)" );

    # Do not dump if nothing to dump
    if( $ev_count eq '0' )
    {
		print STDERR "[!] Nothing to dump\n";
      logMsg( LOG_INFO,  "[!] Nothing to dump" );
    }
    else
    {
      # Generate archive filename & open file
      chomp( $fileName = `date "+%Y%m%d-%H%M"` ); $fileName .= ".sql";
      logMsg( LOG_INFO, "Dumping events to $_ArcPath/$fileName" );
      open( DUMP, ">$_ArcPath/$fileName" ) || die "cannot create dump file $_ArcPath/$fileName : $!";

      logMsg( LOG_INFO, ">> Dump started" );

      # --- Header start
      print DUMP<<EOF;
-- Disable triggers
--UPDATE "pg_class" SET "reltriggers" = 0 WHERE "relname" = 'events';

COPY "events" FROM stdin;
EOF
      # --- Header end

      # Dump events to file
      logMsg( LOG_DEBUG, "SQL: [$qGetEvents], [$fromTime, \"$_ArcTimeout second\"]" );
      $sth = $dbh->prepare( $qGetEvents );
      $sth->execute( ($fromTime, $time_shift) );
      while( @row = $sth->fetchrow_array ) {
        print DUMP join( "\t", @row )."\n";
      }

      # --- Footer start
      print DUMP<<EOF;
\\.
-- Enable triggers
--UPDATE pg_class SET reltriggers = (SELECT count(*) FROM pg_trigger where pg_class.oid = tgrelid) WHERE relname = 'events';
EOF
      # --- Footer end

      logMsg( LOG_INFO, "<< Dump complete" );

      close DUMP || die "cannot close dump file $fileName : $!";

      # Gzip if needed
      if( $_ArcGzip )
      {
        logMsg( LOG_INFO, ">> Gzipping dump" );
        `gzip -9 $_ArcPath/$fileName`;
        $fileName .= ".gz";
        logMsg( LOG_INFO, "<< Gzipping complete" );
      }

      # Get start_time and end_time
      logMsg( LOG_DEBUG, "SQL: [$qGetTimes], [$fromTime, \"$_ArcTimeout second\"]" );
      $sth = $dbh->prepare( $qGetTimes );
      $sth->execute( ($fromTime, $time_shift) );
      @row = $sth->fetchrow_array;
		  $start_time = $row[0]; $end_time = $row[1];

      # Add archive record to table archives
      logMsg( LOG_DEBUG, "SQL: [$qInsArchive], [$start_time, $end_time, $fileName]" );
      $sth = $dbh->prepare( $qInsArchive );
      $sth->execute( ($start_time, $end_time, $fileName) );
      logMsg( LOG_INFO, "Archive record added to DB" );
    } # Dump section

    logMsg( LOG_INFO, ">> Deleting old archive files" );

    # Delete old archive files
    logMsg( LOG_DEBUG, "SQL: [$qGetArchives], [\"$_ArcDelTimeout second\"]" );
    $sth = $dbh->prepare( $qGetArchives );
    $sth->execute( $time_delete);
    while( @row = $sth->fetchrow_array ) {
      unlink "$_ArcPath/$row[0]";
      logMsg( LOG_INFO, "Archive file $_ArcPath/$row[0] deleted" );
    }

    # Delete archive records
    logMsg( LOG_DEBUG, "SQL: [$qDelArchives], [\"$_ArcDelTimeout second\"]" );
    $sth = $dbh->prepare( $qDelArchives );
    $sth->execute( $time_delete );

    logMsg( LOG_INFO, "<< Archives deleted" );

    # Clear archived records from events table
    logMsg( LOG_DEBUG, "SQL: [$qDelEvents], [$fromTime, \"$_ArcTimeout second\"]" );
    $dbh->do( $qDelEvents, undef, ($fromTime, $time_shift) );
	
    logMsg( LOG_INFO, "Events purged" );

    # Finally commit transaction
    $dbh->commit;

    # Vacuum events
    $dbh->{AutoCommit} = 1;
    $dbh->do( $qVacuumEvt );
    logMsg( LOG_INFO, "Events vacuumed" );
    $dbh->{AutoCommit} = 0;
  };

  if ($@) {
    $dbh->rollback;
    warn "Transaction aborted because $@";
    die "Transaction aborted because $@";
  }

  &dbDisconnect;
}

# ------------------------------------------------------------------------------
# Database utilities
# ------------------------------------------------------------------------------
sub dbConnect {
  my $dsn = "dbi:Pg:dbname=$_DBName".($_DBHost ne ''? ";host=$_DBHost":"").($_DBPort ne ''?";port=$_DBPort":"");
  logMsg( LOG_DEBUG, "DBI connect('$dsn','$_DBUser',...)" );

  $dbh = DBI->connect( $dsn, $_DBUser, $_DBPass ) || die $DBI::errstr;
  $dbh->{AutoCommit} = 0;  # enable transactions
  $dbh->{RaiseError} = 1;
}

sub dbDisconnect {
  $dbh->disconnect;
}

sub timeshiftCalculate{
		my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
		my $back_time=timelocal($sec,$min,$hour,$mday,$mon,$year) - $_ArcTimeout;
		my @time = localtime($back_time);
		my $oops      = strftime '%Y-%m-%d %H:%M:%S', @time;
		
		return $oops;
	}


sub timedeleteCalculate{
		my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
		my $back_time=timelocal($sec,$min,$hour,$mday,$mon,$year) - $_ArcDelTimeout;
		my @time = localtime($back_time);
		my $oops      = strftime '%Y-%m-%d %H:%M:%S', @time;
		
		return $oops;
	}
# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------
sub usage {
  print <<EOF;
Usage: $0 {--start [N{d|h|m}]|--stop|--dump}

  --start [N{d|h|m}]  Schedule this script to be run using crontab daemon. If N set,
                      sets period equal to N 'd'ays / 'h'ours / 'm'inutes. If not,
                      period is read from configuration file.
  --stop              Remove schedule from crontab config.
  --dump              Perfom dump.

EOF
  exit;
}



