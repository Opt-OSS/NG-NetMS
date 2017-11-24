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
#@method
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


#@returns DBIx::Migration
has mirate_handler => (
        is      => 'ro',
        builder => 1,
        laizy=>1,
    );
sub _build_mirate_handler {
    my $self = shift;
    return  DBIx::Migration->new(
        {
            dsn      => 'DBI:Pg:dbname='.$self->dbname.';host='.$self->dbhost.';port='.$self->dbport.'',
            dir      => $ENV{NGNMS_HOME}.'/database/migrations',
            debug    => $self->debug,

            password => $self->dbpassword,
            username => $self->dbuser
        }
    );
}

sub _do_migrate{
    my ($self,$version) = (shift,shift);
    my $errors;
    {
        open (local *STDOUT, '>', \( $errors));
        if ($version){
            $self->mirate_handler->migrate($version);
        }else{
            $self->mirate_handler->migrate();
        }

    }
    $self->logger->debug($errors) if $errors;
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
                $self->_do_migrate($self->upgrade);

        }else{
            $self->_do_migrate();
        }
        my $new_version = int($self->version());
        if ($new_version > $version){
            $self->logger->info("Database Upgraded  to version $new_version ") ;
        }else{
            $self->logger->error("Database Upgraded  only to version $new_version, desired version was ".$self->upgrade) ;
        }
    }
    if (defined $self->downgrade){
        $self->logger->info("DOWNgrading from  $version to ".$self->downgrade);
        if ($version < $self->downgrade ){
            $self->logger->error( "Current version is less than desired");
            return;
        }
        if ($version eq $self->downgrade ){
            $self->logger->warn( "Database already at version $version ");
            return;
        }
        $self->_do_migrate( $self->downgrade );
        my $new_version = int($self->version());
        if ($new_version > $version){
            $self->logger->info("Database Downgraded to version $new_version ") ;
        }else{
            $self->logger->error("Database Downgraded  to version $new_version, desired version was ".$self->downgrade) ;
        }
    }

   ;
}
sub version() {
    my $self = shift;
    return $self->mirate_handler->version();
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
