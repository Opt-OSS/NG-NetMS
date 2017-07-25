package Net::Appliance::Session::Engine;
{
  $Net::Appliance::Session::Engine::VERSION = '4.142720';
}

use Moo::Role;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(Int);

has 'pager_enable_lines' => (
    is => 'rw',
    isa => Int,
    required => 0,
    default => quote_sub('24'),
);

has 'pager_disable_lines' => (
    is => 'rw',
    isa => Int,
    required => 0,
    default => quote_sub('0'),
);

sub enable_paging {
    my $self = shift;

    return unless $self->do_paging;
    return unless $self->logged_in;

    my $privstate = $self->in_privileged_mode;
    $self->begin_privileged if $self->privileged_paging;

    my $pagercmd = ($self->nci->phrasebook->has_macro('enable_paging')
        ? 'enable_paging' : 'paging');

    $self->macro($pagercmd, { params => [
        $self->pager_enable_lines
    ]} );

    $self->end_privileged
        if $self->privileged_paging and not $privstate;
}

sub disable_paging {
    my $self = shift;

    return unless $self->do_paging;
    return unless $self->logged_in;

    my $privstate = $self->in_privileged_mode;
    $self->begin_privileged if $self->privileged_paging;

    my $pagercmd = ($self->nci->phrasebook->has_macro('disable_paging')
        ? 'disable_paging' : 'paging');

    $self->macro($pagercmd, { params => [
        $self->pager_disable_lines
    ]} );

    $self->end_privileged
        if $self->privileged_paging and not $privstate;
}

# method to enter privileged mode on the remote device.
# optionally, use a different username and password to those
# used at login time. if using a different username then we'll
# explicily login rather than privileged.

sub begin_privileged {
    my $self = shift;
    my $options = Net::Appliance::Session::Transport::ConnectOptions->new(@_);

    return unless $self->do_privileged_mode;
    return if $self->in_privileged_mode;

    die 'must connect before you can begin_privileged'
        unless $self->logged_in;

    # rt.cpan#47214 check if we are already enabled by peeking the prompt
    if ($self->prompt_looks_like('privileged')) {
        $self->in_privileged_mode(1);
        return;
    }

    # default is to re-use login credentials
    my $username = $options->has_username ? $options->username : $self->get_username;

    # rt.cpan#69139 support passing of privileged_password to the constructor
    my $password = $options->has_password ? $options->password :
                   $self->has_privileged_password ? $self->get_privileged_password
                                                               : $self->get_password;

    $self->macro('begin_privileged');

    # whether login or enable, we still must be prepared for username
    if ($self->prompt_looks_like('user')) {
        die 'a set username is required to enter priv on this host'
            if not $username;
  
        $self->cmd($username, { match => 'pass' });
    }

    if ($self->prompt_looks_like('pass')) {
        die 'a set password is required before begin_privileged'
            if not $password;

        # rt.cpan#92376 timeout when incorrect password
        $self->cmd($password, { match => 'generic' });
    }

    $self->prompt_looks_like('privileged')
        or die 'should be in privileged mode but prompt does not match';
    $self->in_privileged_mode(1);
}

sub end_privileged {
    my $self = shift;
    
    return unless $self->do_privileged_mode;
    return unless $self->in_privileged_mode;

    die 'must leave configure mode before leaving privileged mode'
        if $self->in_configure_mode;

    $self->macro('end_privileged');

    not $self->prompt_looks_like('privileged')
        or die 'should have left privileged mode but prompt still matches';
    $self->in_privileged_mode(0);
}

sub begin_configure {
    my $self = shift;

    return unless $self->do_configure_mode;
    return if $self->in_configure_mode;

    die 'must enter privileged mode before configure mode'
        unless $self->in_privileged_mode;

    # rt.cpan#47214 check if we are already in config by peeking the prompt
    if ($self->prompt_looks_like('configure')) {
        $self->in_configure_mode(1);
        return;
    }

    $self->macro('begin_configure');

    $self->prompt_looks_like('configure')
        or die 'should be in configure mode but prompt does not match';
    $self->in_configure_mode(1);
}

sub end_configure {
    my $self = shift;

    return unless $self->do_configure_mode;
    return unless $self->in_configure_mode;

    $self->macro('end_configure');

    # we didn't manage to escape configure mode (must be nested?)
    if ($self->prompt_looks_like('configure')) {
        my $caller3 = (caller(3))[3];

        # max out at three tries to exit configure mode
        if ( $caller3 and $caller3 =~ m/end_configure$/ ) {
             die 'failed to leave configure mode';
        }
        # try again to exit configure mode
        else {
            $self->end_configure;
        }
    }

    # return if recursively called
    my $caller1 = (caller(1))[3];
    if ( defined $caller1 and $caller1 =~ m/end_configure$/ ) {
        return;
    }

    not $self->prompt_looks_like('configure')
        or die 'should have exited configure mode but prompt still matches';
    $self->in_configure_mode(0);
}

1;
