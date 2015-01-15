#!/usr/bin/perl -w

use Data::Dumper;
use NGNMS_DB;
use DateTime;

my $dbhost = "localhost";
my $dbname = "";
my $dbuser = "";
my $dbpasswd = "";
my $dbport = "5432";

##Get data from command line
while (($#ARGV >= 0) && ($ARGV[0] =~ /^-.*/)) {
	if ($ARGV[0] eq "-L") {
		shift @ARGV;
		$dbhost = $ARGV[0] if defined($ARGV[0]);
		shift @ARGV;
		next;
	}
  	
	if ($ARGV[0] eq "-D") {
		shift @ARGV;
		$dbname = $ARGV[0] if defined($ARGV[0]);
		shift @ARGV;
		next;
	}
  
  if ($ARGV[0] eq "-U") {
		shift @ARGV;
		$dbuser = $ARGV[0] if defined($ARGV[0]);
		shift @ARGV;
		next;
  }
  
  if ($ARGV[0] eq "-W") {
		shift @ARGV;
		$dbpasswd = $ARGV[0] if defined($ARGV[0]);
		shift @ARGV;
		next;
  }
    
  if ($ARGV[0] eq "-P") {
    shift @ARGV;
    $dbport = $ARGV[0] if defined($ARGV[0]);
	shift @ARGV;
    next;
  }
  
}

## Change access to DB
	my $file = "audit_run.sh";  
	open (IN, $file) || die "Cannot open file ".$file." for read";       
			@lines=<IN>;    
	close IN;  
  
	open (OUT, ">", $file) || die "Cannot open file ".$file." for write";  
	foreach $line (@lines)  
	{    
		$line="HOST='$dbhost'\n" if $line =~ m/^HOST/;
		$line="DB='$dbname'\n" if $line =~ m/^DB/;
		$line="USER='$dbuser'\n" if $line =~ m/^USER/;
		$line="PASSWD='$dbpasswd'\n" if $line =~ m/^PASSWD/;
		print OUT $line;    
	}    
	close OUT;

## Get period and create line from crontab	
    DB_open($dbname,$dbuser,$dbpasswd,$dbport,$dbhost);
    $prom_val = DB_getSettings('perioddiscovery');
    my $period = $prom_val->[0];
    if($period <60)
	{
		$sc .= "*/$period  *     *     *     *";
	}
	elsif($period <1440)
	{
		$c = $period/60;
		$sc .= "0     */$c  *     *     *"
	}
	elsif($period <10080)
	{
		$c = $period/1440;
		$sc .= "0     0     */$c  *     *"
	}
	else
	{
		$dd = DateTime->now();
		my $nday = $dd->{local_c}->{day_of_week};
		$sc = "0     0     *	  *     */".$nday;
	}
    DB_close();	    
## Open crontab for user ngnms
    $ct = new Config::Crontab( -owner => 'ngnms' );
## read crontab    
    $ct->read;

     ## create an array of crontab objects
    my @lines = ( new Config::Crontab::Comment(-data => '## audit'),
                  new Config::Crontab::Event(-data => $sc.' /home/ngnms/NGREADY/bin/'.$file." >> /var/log/audit.log 2>&1") );

    ## create a block object via lines attribute
    $newblock = new Config::Crontab::Block( -lines => \@lines );
    ##  find block to update
    
	my $oldblock = $ct->block($ct->select(-type => "comment",-data_re => 'audit'));
	if(defined $oldblock)
	{
		## update block in crontab
		$ct->replace($oldblock, $newblock);
		## write changes in crontab
		$ct->write;
	}
	else
	{
		## add this block to crontab file
		$ct->last($newblock);
		## write out crontab file
		$ct->write;
	}
    

