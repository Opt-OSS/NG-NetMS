package NGNMS::DB::Migration;

use strict;
use warnings FATAL => 'all';
use Moo;
use DBIx::Migration;
use MooX::Options;
use Emsgd qw(diag);
option debug => (
        is      => 'ro',
        format  => 'i',
        default => 1,
        doc     => "Show executed SQL statments 0|1, default 1"
    );
option upgrade => (
        is     => 'ro',
        format => 's',
        doc    => "Version to migrate UP or 'latest' to migrate to latest version "
    );
option downgrade => (
        is     => 'ro',
        format => 'i',
        doc    => "Version to migrate DOWN, 0 to remove all changes"
    );

with "NGNMS::DB::CommandLineOptions"; #Command line options and detauls
with "NGNMS::Log4Role";



has mirate_handler => (
        is      => 'ro',
        builder => 1,
        laizy=>1,
    );
sub _build_mirate_handler {
    my $self = shift;

    return DBIx::Migration->new(
        {
            dsn      => 'DBI:Pg:dbname='.$self->dbname.';host='.$self->dbhost.';port='.$self->dbport.'',
            dir      => $ENV{NGNMS_HOME}.'/database/migrations',
            debug    => $self->debug,

            password => $self->dbpassword,
            username => $self->dbuser
        }
    );
}


sub migrate() {
    my $self = shift;
    my $version = int($self->version()||-1);
    $self->logger->info("Migrating DB ");
    if (defined $self->upgrade){
        $self->logger->info("Upgrading from  $version to ".$self->upgrade);
        if ($self->upgrade ne 'latest') {

            if ($version > $self->upgrade) {
                $self->logger->error( "Database version is greater than desired");
                return;
            }
            if ($version eq $self->upgrade) {
                $self->logger->warn("Database already at version $version ");
                return;
            }
            $self->mirate_handler->migrate( $self->upgrade)
        }else{
            $self->mirate_handler->migrate( )
        }


    }
    if (defined $self->downgrade){
        $self->logger->info("DOWNgrading from  $version to ".$self->downgrade);
        if ($version < $self->downgrade ){
            $self->logger->error( "Current version is laess than dsired");
            return;
        }
        if ($version eq $self->downgrade ){
            $self->logger->warn( "Database already at version $version ");
            return;
        }
        $self->mirate_handler->migrate( $self->downgrade )
    }
    $version = int($self->version());
    $self->logger->info("INFO:Database migrated to version $version ");
   ;
}
sub version() {
    my $self = shift;
    return $self->mirate_handler->version();
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
