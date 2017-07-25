#!/usr/bin/perl
use warnings;
use warnings FATAL => 'all';
use strict;
#use NGNMS::Log4;
use Moo;
package  A {

    use Moo;
    use Emsgd qw /diag/;
    use File::Path qw( make_path );
    with "NGNMS::Log4Role";

    has host=>(is=>'rw', default=>'host');

    has workdir => (
            is      => 'rw',
            #default => sub {($ENV{"NGNMS_DATA"} || '.').'/tmp'},
            builder   => 1, lazy=>1,
        );

    sub _build_workdir {
        my ($self) = @_;
        my $wd = ($ENV{"NGNMS_DATA"} || './a/b/c').'/tmp';
        $self->logger->error ("creating ".$wd);
        make_path  $wd;
        $self->logger->logdie ("Cannot create directory $wd: $!\n") unless -d $wd;
        return $wd;
    };

    1;
}

my $app = A->new();
print $app->workdir;