#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;
use Module::Load;
use NGNMS::App;

use Emsgd qw(diag);

#================= Plugin in question
sub vendor {'Extreme'};
#=========================================
#TODO get real SNMP OIDs
sub devices {
    return {
        'X670G2-48x-4q'   => { sysObjectID_0 => ".1.3.6.1.4.1.1916.2.195", sysObjectID_0_string => 'RFC1213-MIB::sysObjectID.0 = OID: CISCO-PRODUCTS-MIB::ciscoC2500' },
        'X450a-24t-STACK' => { sysObjectID_0 => ".1.3.6.1.4.1.1916.2.93", sysObjectID_0_string => 'RFC1213-MIB::sysObjectID.0 = OID: CISCO-PRODUCTS-MIB::ciscoC2500' },
        'X440-24t-10G'    => { sysObjectID_0 => ".1.3.6.1.4.1.1916.9.99.9", sysObjectID_0_string => 'RFC1213-MIB::sysObjectID.0 = OID: CISCO-PRODUCTS-MIB::ciscoC2500' },
    };
}
#=============================================
sub fixtures {File::Basename::dirname(__FILE__).'/fixtures'}
sub module {
    my $v = vendor();
    $v =~ s/-/_/;
    "NGNMS::Plugins::Core::".$v."::PollHost"
};
load  module();
spec_helper "../../test_helper/plugin_test_helper.pl";



## -----------------------------------  DEVICE REQUIRED  ------------------------------------------------------
describe vendor.":: implements" => sub {
        it_should_behave_like "implement required methods";
        it_should_behave_like "implement device support";
        it_should_behave_like "implements device info";
    };
## -----------------------------------  DEVICE SPECIFIC ------------------------------------------------------



runtests unless caller;

