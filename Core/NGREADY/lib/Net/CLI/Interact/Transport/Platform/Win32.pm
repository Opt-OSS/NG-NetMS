package Net::CLI::Interact::Transport::Platform::Win32;
{
  $Net::CLI::Interact::Transport::Platform::Win32::VERSION = '2.143070';
}

use Moo;
extends 'Net::CLI::Interact::Transport::Wrapper::IPC_Run';

{
    package # hide from pause
        Net::CLI::Interact::Transport::Platform::Options;
    use Moo;
    extends 'Net::CLI::Interact::Transport::Wrapper::Options';
}

1;
