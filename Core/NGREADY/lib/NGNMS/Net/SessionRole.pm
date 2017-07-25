package NGNMS::Net::SessionRole;
use strict;
use warnings FATAL => 'all';
use Moo::Role;

=head2 Attributes

=head3 reply

returns predefined reply for given macro.

    -if reply text could be resolved as file name in  `reply_dir` and file exists returns file content
    -otherwise returns reply text

=head3 reply_dir

dir for lookup for filname with relpy text


    if not reply macro defined and play_dir defined
    then returns content of file in {play_dir}/{macro}.txt
    if file not exists returns undef
    reply has priority over play_dir

=cut

has 'connection' => (
    is => 'rw',

);
has 'reply' => (
    is      => 'rw',
    default => sub {
        { 'cmd1' => 'responce_file_name' };
    }
);
has 'reply_dir' => ( is => 'ro', default => $ENV{'NGNMS_DATA'} || '.' );

has play_dir => (
    is     => 'rw',
    format => 's',
);

has record => (
    is      => 'ro',
    default => 1,
);
has record_dir => (
    is      => 'rw',
    default => ($ENV{'NGNMS_DATA'} || '.') . '/rtconfig',
);
has play => ( is => 'ro', );



requires qw ( connect execute_chained_macro macro);

1;
