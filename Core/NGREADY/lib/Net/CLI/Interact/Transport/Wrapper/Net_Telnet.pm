package Net::CLI::Interact::Transport::Wrapper::Net_Telnet;
{
  $Net::CLI::Interact::Transport::Wrapper::Net_Telnet::VERSION = '2.143070';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(Str InstanceOf);

extends 'Net::CLI::Interact::Transport::Wrapper::Base';

{
    package # hide from pause
        Net::CLI::Interact::Transport::Wrapper::Options;
    use Moo;
    extends 'Net::CLI::Interact::Transport::Wrapper::Base::Options';
}

sub put { (shift)->wrapper->put( join '', @_ ) }

has '_buffer' => (
    is => 'rw',
    isa => Str,
    default => quote_sub(q{''}),
);

sub buffer {
    my $self = shift;
    return $self->_buffer if scalar(@_) == 0;
    return $self->_buffer(shift);
}

sub pump {
    my $self = shift;
    my $content = $self->wrapper->get(Timeout => $self->timeout);
    $self->_buffer($self->_buffer . $content) if defined $content;
}

has '+timeout' => (
    trigger => 1,
);

sub _trigger_timeout {
    my $self = shift;
    if (scalar @_) {
        my $timeout = shift;
        if ($self->connect_ready) {
            $self->wrapper->timeout($timeout);
        }
    }
}

has '+wrapper' => (
    isa => InstanceOf['Net::Telnet'],
);

around '_build_wrapper' => sub {
    my ($orig, $self) = (shift, shift);

    $self->logger->log('transport', 'notice', 'creating Net::Telnet wrapper for', $self->app);
    $self->$orig(@_);

    $SIG{CHLD} = 'IGNORE'
        if not $self->connect_options->reap;

    with 'Net::CLI::Interact::Transport::Role::ConnectCore';
    return $self->connect_core($self->app, $self->runtime_options);
};

after 'disconnect' => sub {
    delete $SIG{CHLD};
};

1;
