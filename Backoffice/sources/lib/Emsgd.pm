    use Data::Dumper;
package Emsgd;

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