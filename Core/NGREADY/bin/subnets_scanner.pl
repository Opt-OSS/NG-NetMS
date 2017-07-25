#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Moo;
use MooX::Options;
use NGNMS::SubnetScannerRunner;
use Try::Tiny qw /try catch/;
use NGNMS::Log4;
use Emsgd qw/diag/;

try{
    my NGNMS::SubnetScannerRunner $app = NGNMS::SubnetScannerRunner->new_with_options();
    $app->run();
}    catch {
    print $_;
    NGNMS::Log4->new('scanner')->error( "Exception:: Scanner : $_"); # not $@
}
