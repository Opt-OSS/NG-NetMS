use warnings FATAL => 'all';
use strict;
package NGNMS::Parser::Config;
use strict;
use warnings FATAL => 'all';
use File::Slurp qw (read_file);
use Moo::Role;

sub cisco_get_configs {
    my ($host, $username, $password, $enablepw) = @_[0 .. 3];
    my $configPath = $_[4];
    my $access = $_[6];
    $community = $_[5]; #this should be global, WTF
    print "Getting configs from $host\n";

    my $er = cisco_connect($host, $username, $password, $enablepw, $access);
    return $er if ( $er !~ m/ok/ );

    # get version
    #
    if (!cisco_get_file('show version', $configPath."_version.txt")) {
        $session->close();
        return $Error;
    }

    # Running config
    #
    $Error = undef;
    my @data = $session->get('show running-config');
    if (!@data) {
        $session->close;
        return "cisco: no data for running config";
    }
    # strip out all lines from the beginning until ! is found
    my $i = 0;
    while ($data[$i] !~ m/!/) {
        $data[$i] = '';
        $i++;
    }

    #    print @data;
    my $fname = $configPath."_running_config.txt";
    if (!open(F_DATA, ">$fname")) {
        $session->close;
        return "Cannot open file $fname for writing: $!";
    }
    print F_DATA @data;
    close (F_DATA);

    # Interfaces
    #
    if (!cisco_get_file('show interfaces', $configPath."_interfaces.txt")) {
        $session->close();
        return $Error;
    }

    $session->close;

    return "ok";
}

sub juniper_get_configs {
    #    my ($host, $username) = @_[0 .. 1];
    #    my @passwds = @_[2 .. 3];
    #    my $configPath = $_[4];
    #    my $acc = $_[6];
    #    print "Getting configs from $host\n";
    #    my @params = ($_[0], $_[1], $_[2], $_[3], '', '', $_[6]);
    #    ##  juniper_create_session(@_);
    #    Emsgd::diag (\@params);
    #    juniper_create_session(@params);

    my ($host, $username, $password, $enablepw) = @_[0 .. 3];
    my $configPath = $_[4];
    #$community = $_[5]; #this should be global, WTF
    my $access = $_[6];

    print "Getting configs from $host\n";
    juniper_create_session($host, $username, $password, $enablepw, $access);
    return $Error if $Error;

    # version
    #
    juniper_get_file('show version', $configPath."_version.txt") or
        return $Error;

    # hardware inventory
    #
    juniper_get_file('show chass hardw', $configPath."_hardware.txt") or
        return $Error;

    # Running config
    #
    juniper_get_file('show config', $configPath."_config.txt") or
        return $Error;

    # Interfaces
    #
    juniper_get_file('show interface extensive', $configPath."_interfaces.txt") or
        return $Error;

    $session->close;

    return "ok";
}
