package Net::CLI::Interact::Transport::Platform::Unix;
{
  $Net::CLI::Interact::Transport::Platform::Unix::VERSION = '2.143070';
}

use Moo;
use Class::Load qw(try_load_class);

BEGIN {
    sub can_use_pty { return try_load_class('IO::Pty') }

    extends (can_use_pty()
        ? 'Net::CLI::Interact::Transport::Wrapper::Net_Telnet'
        : 'Net::CLI::Interact::Transport::Wrapper::IPC_Run');
}

{
    package # hide from pause
        Net::CLI::Interact::Transport::Platform::Options;

    use Moo;
    use Sub::Quote;
    use MooX::Types::MooseLike::Base qw(Int);

    extends 'Net::CLI::Interact::Transport::Wrapper::Options';

    has 'reap' => (
        is => 'rw',
        isa => Int,
        default => quote_sub('0'),
    );
}

1;
