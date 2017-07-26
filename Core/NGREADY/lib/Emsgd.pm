package Emsgd;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $timeout);
@ISA = qw(Exporter);
@EXPORT_OK  = qw(diag pp ss);

use strict;
use warnings;
use Data::Dumper;
use Term::ANSIColor qw(:constants);;

sub ss {
    my @text = shift;
    my $title= shift;
    my $backtrace = shift;

   my $out = Data::Dumper->Dump([@text],[$title || 'message']);
    return $out;

}

sub diag {

    my @text = shift;
    my $title= shift;
    my $backtrace = shift;

    my $count = 0;
    {
        my ($package, $filename, $line, $sub) = caller($count);
        last unless defined $line;
        print STDERR CYAN,sprintf("\n%02i %5i %-35s %-20s", $count++, $line, $sub, $filename);
        last unless $backtrace ;
        redo;
    }
    print STDERR     "\n---------------------------------------------------------------------\n";
    print STDERR  Data::Dumper->Dump([@text],[$title || 'message']);
    #        print "@text";
    print STDERR     "-----------------------------------------------------------------------\n",RESET;
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