package NGNMS::DB::CommandLineOptions;
use strict;
use warnings FATAL => 'all';
use Moo::Role;
use MooX::Options;
option dbname => (
        is      => 'ro',
        short   => 'D',
        format  => 's',
        default => $ENV{NGNMS_DB} || 'ngnms',
        doc     => "Database name"
    );
option dbuser => (
        is      => 'ro',
        short   => "U",
        format  => 's',
        default =>  $ENV{NGNMS_DB_USER} || 'ngnms',
        doc     => "Database user"
    );
option dbpassword => (
        is      => 'ro',
        short   => "W",
        format  => 's',
        default =>  $ENV{NGNMS_DB_PASSWORD} || 'ngnms',
        doc     => "Database password"
    );
option dbhost => (
        is      => 'ro',
        short   => "L",
        format  => 's',
        default => $ENV{NGNMS_DB_HOST} || 'localhost',
        doc     => "Database host"
    );
option dbport => (
        is      => 'ro',
        short   => "P",
        format  => 's',
        default =>  $ENV{NGNMS_DB_PORT} || '5432',
        doc     => "Database port"
    );
1;