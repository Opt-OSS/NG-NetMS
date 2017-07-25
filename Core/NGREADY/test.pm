use strict;
use warnings FATAL => 'all';
use Emsgd qw(diag);
package TEST {
    use Moo;
    with  "NGNMS::Log4Role";

    has workdir => (
            is      => 'rw',
            default => sub {$ENV{"NGNMS_DATA"}.'/tmp'},
            build   => 1,
        );

    sub _build_workdir {
        my ($self) = @_;
        $self->logger->debug ("creating ".$self->workdir);
        mkdir $self->workdir;
        $self->logger->logdie ("Cannot create directory $self->{workdir} : $!\n") unless -d $self->workdir;
    };
}

test->new();