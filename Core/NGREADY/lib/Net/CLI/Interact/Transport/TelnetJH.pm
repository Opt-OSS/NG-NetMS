package Net::CLI::Interact::Transport::TelnetJH;

use Moo;
use Emsgd qw /diag/;

use Sub::Quote;

extends 'Net::CLI::Interact::Transport::Telnet';

sub can_use_pty {return 0}; #allways build wrapped as native
has '+use_net_telnet_connection' => (default => quote_sub('0'));
has '+app' => (is => 'rw', default => 'ssh');
has 'wrapped' => (
        is      => 'lazy',
        builder => sub{
            my $self = shift;
            return 'echo "JUMPHOST CONNECTED" &&  telnet ' . join ' ',
                map {($_ =~ m/\s/) ? ("'" . $_ . "'") : $_}   $self->SUPER::runtime_options(@_)
        }
    );
with "Net::CLI::Interact::Transport::JumpHost";



1;
