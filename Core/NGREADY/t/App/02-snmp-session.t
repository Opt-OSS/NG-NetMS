#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::MockModule;#for syntax only
use Test::Subroutines;
use Test::Spec ;

use NGNMS::App;

use Emsgd qw(diag);
#================= Plugin in question
use NGNMS::Net::SNMPSession;
my NGNMS::Net::SNMPSession $plugin;
sub get_plugin_new {
    return NGNMS::Net::SNMPSession->new;
}
describe "SNMP Session" => sub {
        before each => sub {
                $plugin = get_plugin_new();
                $plugin->connect( 'community', '10.0.1.1', 'hostname' );

                $plugin->stubs( '_run' => sub($){
                        diag \@_;
                        return  @_[1];

                    } );
            };
        it "should query host" => sub {
                my $r = $plugin->queryAny( {
                        oid     => 'OID_IN_Q',
                        version => [ '2c', '1' ],
                        miblist => 'ALL',
                    } );
                is $r, 'snmpget -v 2c -m ALL -c community hostname OID_IN_Q'
            };
        it "should loop by version if no response";
        it "queryAny:: should call queryByHostname first "=>sub{
                $plugin->expects('queryByHostname')->returns('res from queryByHostname')->once;
                $plugin->expects('queryByIp')->never;
                my $r = $plugin->queryAny( {
                        oid     => 'OID_IN_Q',
                        version => [ '2c', '1' ],
                        miblist => 'ALL',
                    } );
                is $r, 'res from queryByHostname'
            };
        it "queryAny:: should call queryByIp if hostname fails"=>sub{
                $plugin->expects('queryByHostname')->returns(undef)->once;
                $plugin->expects('queryByIp')->returns('res from queryByIp')->once;
                my $r = $plugin->queryAny( {
                        oid     => 'OID_IN_Q',
                        version => [ '2c', '1' ],
                        miblist => 'ALL',
                    } );
                is $r, 'res from queryByIp'
            };;
    };
runtests unless caller;

