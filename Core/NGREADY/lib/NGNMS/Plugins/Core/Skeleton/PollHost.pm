package NGNMS::Plugins::Core::Skeleton::PollHost;
use strict;
use warnings FATAL => 'all';
use Moo;
use Emsgd qw(diag);
use File::Basename;
use Net::Netmask;
with "NGNMS::App::PollHostPluginInterface";
with "NGNMS::App::Helpers";

sub checkCanPollHost() {
    return 0;
}

sub prepare_connection {
    die 'Should be implemented';
    my $self    = shift;
    my $params  = shift;
    my $dirname = dirname(__FILE__);
    $params->{personality}         = 'ios';
    $params->{add_library}         = $dirname . '/phrasebook/';
    $params->{requires_privileged} = 0;
    $params->{privileged_paging}   = 0;
    $params->{wake_up}             = 0;
    return $params;
}

sub beforeProcessing {
    die 'Should be implemented';
}

sub getConfig {
    die 'Should be implemented';
}

sub checkSNMPsysObjectID {
    die 'Should be implemented';
}

sub checkDeviceSupported {
    die 'Should be implemented';
}

sub getIpLayer {
    die 'Should be implemented';
}

sub getVendor {
    die 'Should be implemented';
}

sub getLocation {
    return '';
}

sub getHostName {
    die 'Should be implemented';
}

sub getModel {
    die 'Should be implemented';
}

sub getHardware {
    die 'Should be implemented';
}

sub getSoftware {
    die 'Should be implemented';
}

sub getInterfaces {
    die 'Should be implemented';
}


sub ping {
    my $self = shift;
    diag $self;
}

sub getModuleName {
    return __PACKAGE__;
}


1;
