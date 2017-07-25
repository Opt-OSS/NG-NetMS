package Net::CLI::Interact::Transport::Role::ConnectCore;
{
  $Net::CLI::Interact::Transport::Role::ConnectCore::VERSION = '2.143070';
}

use Moo::Role;
use MooX::Types::MooseLike::Base qw(Int);

use Net::Telnet ();

sub connect_core {
    my $self = shift;

    if ($self->use_net_telnet_connection) {
        my $app = shift; # unused
        return $self->_via_native(@_);
    }
    else {
        return $self->_via_spawn(@_);
    }
}

sub _via_native {
    my $self = shift;
    my $t = Net::Telnet->new(Cmd_remove_mode => 1, @_);
    return $t;
}

sub _via_spawn {
    my $self = shift;
    my $t = Net::Telnet->new(
        Binmode         => 1,
        Cmd_remove_mode => 1,
        Telnetmode      => 0,
    );

    $t->fhopen( $self->_spawn_command(@_) )
        or die "failed to spawn connection to target device.";
    return $t;
}

# this code is based on that in Expect.pm, and found to be the most reliable.
# minor alterations to use CORE::close and die, and to reap child.

use FileHandle;
use IO::Pty;
use POSIX qw(WNOHANG);

has 'childpid' => (
    is => 'rw',
    isa => Int,
);

sub REAPER {
    # http://www.perlmonks.org/?node_id=10516
    my $stiff;
    1 while (($stiff = waitpid(-1, &WNOHANG)) > 0);
    $SIG{CHLD} = \&REAPER;
}

sub _spawn_command {
    my $self = shift;
    my @command = @_;
    my $pty = IO::Pty->new();

    # try to install handler to reap children
    $SIG{CHLD} = \&REAPER
        if !defined $SIG{CHLD};

    # set up pipe to detect childs exec error
    my ($stat_rdr, $stat_wtr);
    pipe($stat_rdr, $stat_wtr) or die "Cannot open pipe: $!";
    $stat_wtr->autoflush(1);
    eval {
        fcntl($stat_wtr, F_SETFD, FD_CLOEXEC);
    };

    my $pid = fork;

    if (! defined ($pid)) {
        die "Cannot fork: $!" if $^W;
        return undef;
    }

    if($pid) { # parent
        my $errno;

        CORE::close $stat_wtr;
        $pty->close_slave();
        $pty->set_raw();

        # now wait for child exec (eof due to close-on-exit) or exec error
        my $errstatus = sysread($stat_rdr, $errno, 256);
        die "Cannot sync with child: $!" if not defined $errstatus;
        CORE::close $stat_rdr;

        if ($errstatus) {
            $! = $errno+0;
            die "Cannot exec(@command): $!\n" if $^W;
            return undef;
        }

        # store pid for killing if we're in cygwin
        $self->childpid( $pid );
    }
    else { # child
        CORE::close $stat_rdr;

        $pty->make_slave_controlling_terminal();
        my $slv = $pty->slave()
            or die "Cannot get slave: $!";

        $slv->set_raw();

        CORE::close($pty);

        CORE::close(STDIN);
        open(STDIN,"<&". $slv->fileno())
            or die "Couldn't reopen STDIN for reading, $!\n";
 
        CORE::close(STDOUT);
        open(STDOUT,">&". $slv->fileno())
            or die "Couldn't reopen STDOUT for writing, $!\n";

        CORE::close(STDERR);
        open(STDERR,">&". $slv->fileno())
            or die "Couldn't reopen STDERR for writing, $!\n";

        { exec(@command) };
        print $stat_wtr $!+0;
        die "Cannot exec(@command): $!\n";
    }

    return $pty;
}

1;
