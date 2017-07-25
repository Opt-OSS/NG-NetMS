package NGNMS::DB::Base;
use strict;
use warnings FATAL => 'all';
use Moo::Role;
use DBI;
with "MooX::Singleton";
with "NGNMS::Log4Role";

has host => (
        is => 'ro',
        #        default => $ENV{NGNMS_DB_HOST} || 'localhost'
    );
has port => (
        is => 'ro',
    );
has database => (
        is => 'ro',
    );
has username => (
        is => 'ro',
    );
has password => (
        is => 'ro',
    );

#@returns DBI
has dbh => (
        is => 'rw',
    );

sub BUILD {
    #    Emsgd::diag('db init');
    my $self = shift;
    eval {
        $self->open();

    };

    $self->logger->logdie( "could not connect to database: ".$@) unless $self->dbh;

}
sub open{
    my $self = shift;
    $self->dbh( DBI->connect( "dbi:Pg:dbname=".$self->database.";host=".$self->host.";port=".$self->port.";",

        $self->username,
        $self->password,
        { AutoCommit => 1, Warn => 1, RaiseError => 1, PrintError => 1, ChopBlanks => 1, }
    ));
}

1;