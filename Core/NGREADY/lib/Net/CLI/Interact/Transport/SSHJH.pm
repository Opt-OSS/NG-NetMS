package Net::CLI::Interact::Transport::SSHJH;

use Moo;
use Emsgd qw /diag/;

extends 'Net::CLI::Interact::Transport::SSH';

has 'wrapped' => (
        is      => 'lazy',
        builder => sub{
            my $self = shift;
            return 'echo "JUMPHOST CONNECTED" &&  ssh ' . join ' ',
                map {($_ =~ m/\s/) ? ("'" . $_ . "'") : $_}   $self->SUPER::runtime_options(@_)
        }
    );

with "Net::CLI::Interact::Transport::JumpHost";
1;
