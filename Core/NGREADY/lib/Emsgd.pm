package Emsgd;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $timeout);
@ISA = qw(Exporter);
@EXPORT_OK  = qw(diag pp ss);

use strict;
use warnings;
use Data::Dumper;
use Term::ANSIColor qw(:constants);;
use Carp;

sub ss {
    my @text = shift;
    my $title= shift;
    my $backtrace = shift;

   my $out = Data::Dumper->Dump([@text],[$title || 'message']);
    return $out;

}

sub diag {

    my $text = shift;
    my $title= shift;
    my $backtrace = shift;

    my ($package0, $filename0, $line0, $sub0) = caller(0);
    my ($package, $filename, $line, $sub) = caller(1);
    print  RESET;
    print  "\n",CYAN;
    my $trace = $backtrace
            ? Carp::longmess
            : sprintf("%-35s %-20s line %i",  $sub, $filename0, $line0);
    print  "$trace";
    print      "\n----------------------------  ".($title || '')." ".ref($text)." -----------------------------------------\n";
    print  Dumper($text);

    #        print "@text";
    print      "-----------------------------------------------------------------------\n";
    print  RESET,"\n";
    return 1
}
sub pp {
    my @text = shift;
    my $backtrace = shift;
    print "\n\n===debug V ----------------------------------------------------------";

        my $count = 0;
        {
            my ($package, $filename, $line, $sub) = caller($count);
            last unless defined $line;
            print sprintf("\n%02i %5i %-35s %-20s", $count++, $line, $sub, $filename);
                     last unless $backtrace ;
            redo;
        }
    print "\n===\n";
print Data::Dumper->Dump([@text],[qw(message)]);
#        print "@text";
    print "\n===debug end ^----------------------------------------------------------\n\n";
    return 1;
}


1;
# ABSTRACT: This file is part of open source NG-NetMS tool.