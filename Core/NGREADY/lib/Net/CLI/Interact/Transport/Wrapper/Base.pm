package Net::CLI::Interact::Transport::Wrapper::Base;
{
  $Net::CLI::Interact::Transport::Wrapper::Base::VERSION = '2.143070';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(Int RegexpRef Str Object);

with 'Net::CLI::Interact::Role::FindMatch';

{
    package # hide from pause
        Net::CLI::Interact::Transport::Wrapper::Base::Options;
    use Moo;
}

has 'use_net_telnet_connection' => (
    is => 'rw',
    isa => Int,
    default => quote_sub('0'),
);

has 'irs_re' => (
    is => 'ro',
    isa => RegexpRef,
    default => quote_sub(q{ qr/(?:\015\012|\015|\012)/ }), # first wins
);

has 'ors' => (
    is => 'rw',
    isa => Str,
    default => quote_sub(q{"\n"}),
);

has 'timeout' => (
    is => 'rw',
    isa => quote_sub(q{ die "$_[0] is not a posint!" unless $_[0] > 0 }),
    default => quote_sub('10'),
);

has 'app' => (
    is => 'lazy',
    isa => Str,
    predicate => 1,
    clearer => 1,
);

has 'stash' => (
    is => 'rw',
    isa => Str,
    default => quote_sub(q{''}),
);

has 'wrapper' => (
    is => 'lazy',
    isa => Object,
    predicate => 'connect_ready',
    clearer => 1,
);

sub _build_wrapper {
    my $self = shift;
    $self->logger->log('transport', 'notice', 'connecting with: ',
        $self->app, (join ' ', map {($_ =~ m/\s/) ? ("'". $_ ."'") : $_}
                                   $self->runtime_options));
    # this better be wrapped otherwise it'll blow up
};

sub init { (shift)->wrapper(@_) }

sub flush {
    my $self = shift;
    my $content = $self->stash . $self->buffer;
    $self->stash('');
    $self->buffer('');
    return $content;
}

sub disconnect {
    my $self = shift;
    $self->clear_wrapper;
    $self->flush;
}

sub _abc { die "not implemented." }

sub put { _abc() }
sub pump { _abc() }
sub buffer { _abc() }

sub DEMOLISH { (shift)->disconnect }

sub do_action {
    my ($self, $action) = @_;
    $self->logger->log('transport', 'info', 'callback received for', $action->type);

    if ($action->type eq 'match') {
        my $irs_re = $self->irs_re;
        my $cont = $action->continuation;

        while ($self->pump) {
            # remove control characters
            (my $buffer = $self->buffer) =~ s/[\000-\010\013\014\016-\032\034-\037]//g;
            $self->logger->log('dump', 'debug', "SEEN:\n". $buffer);

            if ($buffer =~ m/^(.*$irs_re)(.*)/s) {
                $self->stash($self->stash . $1);
                $self->buffer($2 || '');
            }

            if ($cont and $self->find_match($self->buffer, $cont->first->value)) {
                $self->logger->log('transport', 'debug', 'continuation matched');
                $self->buffer('');
                $self->put($cont->last->value);
            }
            elsif (my $hit = $self->find_match($self->buffer, $action->value)) {
                $self->logger->log('transport', 'info',
                    sprintf 'output matched %s, storing and returning', $hit);
                $action->prompt_hit($hit);
                $action->response_stash($self->stash);
                $action->response($self->buffer);
                $self->flush;
                last;
            }
            else {
                $self->logger->log('transport', 'debug', "nope, doesn't (yet) match",
                    (ref $action->value eq ref [] ? (join '|', @{$action->value})
                                                : $action->value));
            }
        }
    }
    if ($action->type eq 'send') {
        my $command = sprintf $action->value, @{ $action->params };
        $self->logger->log('dialogue', 'notice', 'queueing data for send: "'. $command .'"');
        $self->put( $command, ($action->no_ors ? () : $self->ors) );
    }
}

1;
