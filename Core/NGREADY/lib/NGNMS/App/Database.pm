package NGNMS::App::Database;
use strict;
use warnings FATAL => 'all';
use Moo::Role;
use MooX::Options;
use NGNMS::DB;
with "NGNMS::Log4Role";
with 'NGNMS::DB::CommandLineOptions';


#@returns NGNMS::DB
has DB => (
        is      => 'rw',
        default => 0,
    );

=head1

    METHODS
    B<get_db()>
    Service to get singleton instance NGNMS::DB
=cut

#@returns NGNMS::DB
sub get_db {
    my $self = shift;
    my $db =  NGNMS::DB->instance(
        domain           => 'public',
        type             => 'main',
        driver           => 'Pg',
        host             => $self->dbhost,
        port             => $self->dbport,
        database         => $self->dbname,
        username         => $self->dbuser,
        password         => $self->dbpassword,
        server_time_zone => 'UTC',
    );
     unless ($db->dbh->ping){
        $db->open();
        $self->logger->debug("Re-opening connectiopn to DB")
    }
    return $db;
}

sub setup_database {
    my $self = shift;
    $self->DB( $self->get_db );
}
1;