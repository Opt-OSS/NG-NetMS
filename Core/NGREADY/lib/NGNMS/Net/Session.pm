package NGNMS::Net::Session;

use strict;
use warnings FATAL => 'all';
use Moo;
use File::Slurp qw /write_file/;
use NGNMS::Net::Connect;
use Emsgd qw(diag);
use NGNMS::EscapeANSI qw/escape_ansi/;
with "NGNMS::Log4Role";
with  "NGNMS::Net::SessionRole";

my $cache = { };

sub connect {
    my ($self,$params,$connect_options )= (shift,shift,shift);
    $params->{debug} = $params->{debug} || 'error';
    $self->verbose( uc($params->{verbose} || 'error'));
    #$self->set_logger(ref($self).'.'.$params->{host});
    $self->connection( NGNMS::Net::Connect->new($params) );
    my $res = "RouterHost: failed to connect and ena to host";
    eval {
        $self->connection->connect($connect_options);
        die "Login status is 0" unless $self->connection->logged_in;
        if ($params->{requires_privileged}) {
            $self->logger->debug( "Starting priveleged");
            $self->connection->begin_privileged();
            die  "Could not enter privileged" unless $self->connection->in_privileged_mode;
        }
        $res = 'ok';
    };
    if ($@) {
        $res = $@;
        $res =~ s/[\n\r]/;/g;
        $self->logger->warn("Could not login, the reported error was : ".$res);
    }
    return $res;
}



sub execute_chained_macro {
    my $self = shift;
    my @chained_commands = @_;

    my $res;
    for my $macro (@chained_commands) {
        $res .= $self->macro($macro);
    }
    return $res;
}
#=head2 macro
#
#executes macro on remote host.
#it returns cached responce by default if $params == undef
#it use cache
#    - if $params undefined
#    - if $params->{cached} = 1
#
#=cut

sub macro{
    my $self = shift;
    my $macro = shift;
    my $params = shift;
    my $use_cached = 1;
    if ($params) {
        $use_cached = $params->{cache}
    }
    my $macro_cached_name = $macro;
    if ($use_cached && defined $params->{params}) {
        #join params
        $macro_cached_name = $macro.'_'.join('_', @{$params->{params}});
    }
    #make cache-key file-name safe
    $macro_cached_name =~ s/[^A-Za-z0-9\-\.]/\_/g;

    #    my $app = NGNMS::App->instance();
    #    diag $app;
    #    diag $self->connection;
    return $cache->{$macro_cached_name} if defined $cache->{$macro_cached_name} && $use_cached;
    $self->logger->debug("executing '$macro'");
    my $text = $self->connection->macro( $macro, $params );
    escape_ansi( \$text );
    $self->__record( $macro_cached_name, $text, $params ) if $self->record;
    #save to cache if no parqams given
    $cache->{$macro_cached_name} = $text if $use_cached;
    return $text;
}

sub close() {
    my $self = shift;
    $self->connection->close();
}

#=for
# write executed commands into directory if App mode is 'record'
#
#=cut

sub __record {

    my $self = shift;
    my $macro_cached_name = shift;
    my $text = shift;

    File::Slurp::write_file( $self->record_dir.'/'.$macro_cached_name.'.txt', $text );

    return 1;
}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.

