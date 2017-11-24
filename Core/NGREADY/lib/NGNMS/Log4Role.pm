package NGNMS::Log4Role;

use strict;
use warnings FATAL => 'all';
use Moo::Role;
use Log::Log4perl;
use NGNMS::Log4Trapper;


use Emsgd qw/diag/;
#@returns NGNMS::Log4Role
has logger => (
        is => 'rw',
        builder => 1,
        lazy => 1,
    );
has verbose => (
    is =>'rw',
#        builder=> 1,
        default=>sub{ $ENV{NGNMS_DEBUG} || 'INFO' }
);
sub BUILD {
    Log::Log4perl->init_once($ENV{NGNMS_LOGCONF}||$ENV{NGNMS_HOME}."/bin/log4perl.conf");
    Log::Log4perl::MDC->put('host','') unless Log::Log4perl::MDC->get('host');
#    tie *STDERR, "NGNMS::Log4Trapper";
}
#sub BUILDARGS{
#    my ($class, @args) = @_;
#    # accept single hash ref or naked hash
#    my $params = (ref {} eq ref $args[0] ? $args[0] : {@args});
#    $params->{verbose} =( $ENV{NGNMS_DEBUG} || 'ERROR')  unless exists $params->{verbose};
#        return $params;
#
#}
sub _get_host_for_log{
    my $self = shift;
    if ($self->can( 'host') || defined $self->{host}){
        return '.'.$self->host;
    }
    if (defined $self->{session}->{connection}){
        return '.'.$self->{session}->{connection}->{host};
    }
    return '';
}

sub put_debug_key{
    my ($self,$key,$val) = @_;
    Log::Log4perl::MDC->put($key,$val );
}



#@returns NGNMS::Log4Role
sub get_new_category_logger {
    my $self=shift;
    my $category=shift;
    #    local $Log::Log4perl::Filter::verbose_level = uc($self->verbose);
    #    diag ($Log::Log4perl::Filter::verbose_level,ref($self),1);]
    my $logger = Log::Log4perl->get_logger($category);
    return $logger
}
#sub _build_verbose{
#    diag \@_;
#    my ($self) = shift;
#    my $verbose  =  $ENV{NGNMS_DEBUG} || 'ERROR';
#    return $verbose;
#}
sub _build_logger  {
    my $self=shift;
    return $self->get_new_category_logger(ref($self));
#    local $Log::Log4perl::Filter::verbose_level = uc($self->verbose);
#    diag ($Log::Log4perl::Filter::verbose_level,ref($self),1);]
#    Log::Log4perl->init_once("/home/ngnms/NGREADY/bin/log4perl.conf");
#    my $logger = Log::Log4perl->get_logger( ref($self));
#    Log::Log4perl::DataDumper::override($logger);
#    return $logger
}


1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
