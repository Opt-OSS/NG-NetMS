package Net::CLI::Interact::Transport::Wrapper::IPC_Run;
{
  $Net::CLI::Interact::Transport::Wrapper::IPC_Run::VERSION = '2.143070';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(ScalarRef InstanceOf);

extends 'Net::CLI::Interact::Transport::Wrapper::Base';

{
    package # hide from pause
        Net::CLI::Interact::Transport::Wrapper::Options;
    use Moo;
    extends 'Net::CLI::Interact::Transport::Wrapper::Base::Options';
}

use IPC::Run ();

has '_in' => (
    is => 'rw',
    isa => ScalarRef,
    default => sub { \eval "''" },
);

# writer for the _in slot
sub put { ${ (shift)->_in } .= join '', @_ }

has '_out' => (
    is => 'ro',
    isa => ScalarRef,
    default => sub { \eval "''" },
);

sub buffer {
    my $self = shift;
    return ${ $self->_out } if scalar(@_) == 0;
    return ${ $self->_out } = shift;
}

# clearer for the _out slot
has '_err' => (
    is => 'ro',
    isa => ScalarRef,
    default => sub { \eval "''" },
);

has '_timeout_obj' => (
    is => 'lazy',
    isa => InstanceOf['IPC::Run::Timer'],
);

sub _build__timeout_obj { return IPC::Run::timeout((shift)->timeout) }

has '+timeout' => (
    trigger => quote_sub(q{(shift)->_timeout_obj->start(shift) if scalar @_ > 1}),
);

has '+wrapper' => (
    isa => InstanceOf['IPC::Run'],
    handles => ['pump'],
);

around '_build_wrapper' => sub {
    my ($orig, $self) = (shift, shift);

    $self->logger->log('transport', 'notice', 'booting IPC::Run harness for', $self->app);
    $self->$orig(@_);

    return IPC::Run::harness(
        [$self->app, $self->runtime_options],
            $self->_in,
            $self->_out,
            $self->_err,
            $self->_timeout_obj,
    );
};

before 'disconnect' => sub {
    my $self = shift;
    $self->wrapper->kill_kill(grace => 1);
};

1;
