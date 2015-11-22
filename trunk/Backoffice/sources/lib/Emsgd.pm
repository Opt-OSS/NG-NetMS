# DEBUG OUTPUT PACKAGE
use strict;
use warnings;
use Data::Dumper;
package Emsgd;
sub ss {
    my @text = shift;
    my $backtrace = shift;
    my $out = '';
    $out .= "\n\n===debug V ----------------------------------------------------------";

    my $count = 0;
    {
        my ($package, $filename, $line, $sub) = caller($count);
        last unless defined $line;
        $out .= sprintf("\n%02i %5i %-35s %-20s", $count++, $line, $sub, $filename);
        last unless $backtrace ;
        redo;
    }
    $out .= "\n===\n";
    $out .= Data::Dumper->Dump([@text],[qw(message)]);
    #        print "@text";
    $out .= "\n===debug end ^----------------------------------------------------------\n\n";

}
sub diag {
    my @text = shift;
    my $backtrace = shift;
    print STDERR "\n\n===debug V ----------------------------------------------------------";

    my $count = 0;
    {
        my ($package, $filename, $line, $sub) = caller($count);
        last unless defined $line;
        print STDERR  sprintf("\n%02i %5i %-35s %-20s", $count++, $line, $sub, $filename);
        last unless $backtrace ;
        redo;
    }
    print STDERR  "\n===\n";
    print STDERR  Data::Dumper->Dump([@text],[qw(message)]);
    #        print "@text";
    print STDERR  "\n===debug end ^----------------------------------------------------------\n\n";
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
}

sub print {
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
} # Warning
1;