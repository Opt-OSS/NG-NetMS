package Net::Appliance::Session::Scripting;

use strict;
use warnings FATAL => 'all';

use Getopt::Long 2.24 qw(:config bundling);
use Term::ANSIColor qw(colored);
use Text::ParseWords qw(shellwords);
use Term::ReadPassword qw(read_password);
$Term::ReadPassword::USE_STARS = 1;
use IO::Prompt::Tiny qw(prompt);
use IO::Handle ();
use Cwd qw(abs_path);
use Data::Dumper ();
use Try::Tiny;
use Text::Glob qw(match_glob);

use Net::Appliance::Session;

our $VERSION = $Net::Appliance::Session::VERSION || '0.00031412';
my $banner = colored ['blue'],
  "Net Appliance Session scripting - v$VERSION - © 2012 by Oliver Gorwits\n";

my %options = (cloginrc_opts => {});
my $exit_status = 0;

sub bailout {
    if (scalar @_) {
        print "\n", colored(['magenta bold'], @_) if scalar @_;
    }
    else {
        print $banner;
    }
    print <<ENDUSAGE;

  nas [options] [hostname or IP]

  -p, --personality  Device <personality> (default: "ios")
  -t, --transport    <transport> method (Serial, Telnet, default: SSH)
  -u, --username     <username> to connect as on device (default: \$USER)
                     
  -R, --record       Record session
  -P, --playback     Play back session
  -s, --script       When recording, save playback script to this <filename>
  -l, --cmdlog       NAS <file> to record commands to, or play them back from
                     
  -e, --exit-last    Num. of output lines from last command is program exit status
  -c, --cloginrc     RANCID cloginrc <file> with device credentials
  -z, --nopassword   Do not ask for device password (if not using cloginrc)
  -o, --echo         Echo commands sent, when playing back the recorded script/cmdlog
  -M, --paging       Do not attempt to disable command output paging
  -B, --nobanner     Suppress display of any login banner received from the device
                     
  -q, --quiet        Hide informational messages
  -v, --verbose      NCI log <level> ("debug", "notice", "info", etc)
  -V, --version      Display this program's version number
  -h, --help         Display this help text

Notes:
* If hostname or IP is not specified, the script loops, waiting for hostnames
to be entered passed on standard input, each one starting a new session.
* When you disconnect from an interactive session there may be an input/output
read error. You should run "!s close" to request a graceful disconnection.

ENDUSAGE

    exit(0);
}

sub getopt {
    my @getoptconf = (qw/
        personality|p=s
        transport|t=s
        username|u=s

        record|R
        playback|P
        script|s=s
        cmdlog|l=s

        exit-last|e
        cloginrc|c=s
        nopassword|z
        echo|o
        paging|M
        nobanner|B

        quiet|q
        verbose|v=s
        help|h
        version|V
    /);

    unshift @ARGV, shellwords($ENV{PERL_NAS_OPT});
    %options = (map {$_ => $main::defaults->{$_}} keys %$main::defaults);
    GetOptions(\%options, @getoptconf) || bailout();
    $options{hostname} = $ARGV[0] if scalar @ARGV;
}

sub commandline {
    bailout() if exists $options{help};

    if (exists $options{version}) {
        print "nas version $VERSION\n";
        exit(0);
    }

    if (exists $options{verbose}) {
        $ENV{NCI_LOG_AT} = $options{verbose};
    }

    # checks for incompatible/nonsense command option combinations
    bailout("error: Cannot Record (-R) and Playback (-P) at the same time.\n")
        if $options{record} and $options{playback};

    bailout("error: Record needs either command log file (-l) or script name (-s).\n")
        if $options{record} and not ($options{script} or $options{cmdlog});

    bailout("error: Makes no sense to have both command log file (-l) and script (-s).\n")
        if $options{cmdlog} and $options{script};

    bailout("error: Please specify hostname or IP on command line if recording.\n")
        if $options{record} and not $options{hostname};

    # hello there, user
    print $banner if not exists $options{quiet};

    # login credentials
    if (not exists $options{cloginrc}) {
        if (not exists $options{username}) {
            $options{username} = prompt('Username:', $ENV{USER});
        }
        if (not exists $options{nopassword}) {
            $options{password} = read_password(colored ['white'], 'Password (optional): ');
            bailout("error: No login password and no cloginrc (-c) file (need -z ?).\n")
                if not length $options{password};
        }
    }
}

sub get_creds_from_cloginrc {
    return unless $options{cloginrc} and -e $options{cloginrc};
    open my $cloginrc, '<', $options{cloginrc} or bailout("$!\n");

    my %t_map = (telnet => 'Telnet', 'ssh' => 'SSH');
    my @find = qw(autoenable method timeout user password);
    my %found = (map {$_ => 0} @find);

    while (<$cloginrc>) {
        my $line = $_;
        next unless defined $line and length $line and $line =~ m/^add /;

        foreach my $f (@find) {
            next unless $line =~ m/^add\s+$f\s+(\S+)\s+(\S+)(?:\s+(\S+))?/;
            my ($host, $value, $value2) = ($1, $2, $3);

            next unless match_glob($host, $options{hostname});
            next if $found{$f}++;

            if ($f eq 'autoenable') {
                $options{cloginrc_opts}{do_privileged_mode} = not $value;
            }
            elsif ($f eq 'method') {
                $options{cloginrc_opts}{transport} = $t_map{$value}
                    if not exists $options{transport};
            }
            elsif ($f eq 'timeout') {
                $options{cloginrc_opts}{timeout} = $value;
            }
            elsif ($f eq 'user') {
                $options{cloginrc_opts}{username} = $value
                    if not exists $options{username};
            }
            elsif ($f eq 'password') {
                $options{cloginrc_opts}{password} = $value;
                $options{cloginrc_opts}{privileged_password} = $value2
                    if defined $value2 and length $value2;
            }
        }
    }
}

sub run {
    getopt();
    commandline();

    if (not exists $options{hostname}) {
        if (not exists $options{quiet}) {
            print colored ['green'],
                qq{Now looping, waiting for hostnames on standard input...\n};
        }

        while (<>) {
            $options{hostname} = $_;
            chomp $options{hostname};
            next if not length $options{hostname};
            get_creds_from_cloginrc();
            do_session(%options);
        }
    }
    else {
        do_session(%options);
    }

    exit($exit_status);
}

sub do_session {
    my (%options) = @_;

    # scripting sources
    my $script_read = IO::Handle->new();
    my $command_log = IO::Handle->new();

    if ($options{cmdlog}) {
        if ($options{playback}) {
            open $script_read, '<', $options{cmdlog};
            if (not $options{quiet}) {
                print colored ['green'], "Playing back command log...\n";
            }
        }
        elsif ($options{record}) {
            open $command_log, '>', $options{cmdlog};
            if (not $options{quiet}) {
                print colored ['green blink'], "Recording command log!\n";
            }
        }
    }

    if ($options{record} and $options{script}) {
        open $command_log, '>', $options{script};
        open my $source, '<', abs_path($0);
        while (<$source>) { print $command_log $_ unless $_ =~ m/__END__/ }
        close $source;

        my %settings = (%options, playback => 1);
        delete $settings{$_}
            for qw/record script cmdlog password nopassword cloginrc_opts/;
        print $command_log "BEGIN {\n    our ";
        print $command_log Data::Dumper->Dump([\%settings], ['defaults']);
        print $command_log "}\n\n";
        print $command_log "__DATA__\n";

        print colored ['green blink'], "Recording session!\n"
            if not $options{quiet};
    }

    # informational messages if not in quiet mode
    if (not exists $options{quiet}) {
        my @messages = ();
        if (not exists $options{personality}) {
            push @messages, qq{personality "/cisco/ios"};
        }
        if (not exists $options{transport}
                or not exists $options{cloginrc_opts}{transport}) {
            push @messages, 'transport SSH';
        }
        if (scalar @messages) {
            print colored ['green'], 'Assuming '. (join ' and ', @messages), ".\n";
        }
    }

    print colored ['white'], "Connecting to [$options{hostname}]...\n\n"
        if not $options{quiet};

    my $s = Net::Appliance::Session->new({
        host => $options{hostname},
        transport => ($options{transport} || 'SSH'),
        personality => ($options{personality} || 'ios'),
        ($options{username} ? (username => $options{username}) : ()),
        ($options{password} ? (password => $options{password}) : ()),
        (($options{quiet} and ($options{transport} eq 'SSH'
                or $options{cloginrc_opts}{transport} eq 'SSH')) ? (
            connect_options => { opts => ['-q'] },
        ) : ()),
        %{ $options{cloginrc_opts} || {} },
    });

    if ($options{paging}
        or not ($s->nci->phrasebook->has_macro('enable_paging')
                    or $s->nci->phrasebook->has_macro('paging'))) {
        $s->do_paging(0);
    }

    try {
        $s->connect();
        print $s->last_response if not $options{nobanner};

        while (1) {
            my $cmd = get_next_cmd($s, $script_read);
            last if not defined $cmd;
            next if $cmd =~ m/^\s+$/;
            if ($command_log->opened) {
                print $command_log "$cmd\n";
                $command_log->flush;
            }

            if ($cmd =~ m/^!m\s+(\S+)(?:\s+(.+))?/) {
                my ($name, $args) = ($1, $2);
                $args = '' if not defined $args;
                print colored ['white bold'], "Running macro [$name]...\n"
                    if not $options{quiet};
                $s->macro($name, { params => [split /\s+/, $args] });
                next;
            }
            elsif ($cmd =~ m/^!m/) {
                print colored ['white bold'], "Macro Names:\n";
                foreach my $m ($s->nci->phrasebook->macro_names) {
                    print colored ['white bold'], "  $m\n";
                }
                next;
            }
            elsif ($cmd =~ m/^!s\s+(\S+)/) {
                my $call = $1;
                if (not $s->can($call)) {
                    print colored ['red bold'], "NAS cannot do [$call]\n";
                }
                else {
                    print colored ['white bold'], "Running session call [$call]...\n"
                        if not $options{quiet};
                    $s->$call;
                    last if not $s->logged_in;
                }
                next;
            }
            elsif ($cmd =~ m/^\\!m/) {
                $cmd =~ s/^\\//;
            }

            my @last_response = $s->cmd($cmd);
            $exit_status = scalar @last_response if $options{'exit-last'};
            print join '', @last_response;
        }
    }
    catch {
        print colored ['white bold'], $_;
    }
    finally {
        $s->close;
    };
}

sub get_next_cmd {
    my ($s, $script_read) = @_;
    my $turtle = colored ['red'], '>> ';

    if ($options{playback}) {
        no warnings 'once';
        my $cmd = ($options{cmdlog} ? <$script_read> : <main::DATA>);
        return if not defined $cmd;
        chomp $cmd;
        print $turtle, $s->nci->last_prompt, $cmd, "\n"
            if not $options{echo};
        return $cmd;
    }
    else {
        prompt($turtle . $s->last_prompt);
    }
}

1;
