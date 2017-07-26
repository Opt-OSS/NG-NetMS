package NGNMS::Net::Emulator::Host;

use strict;
use warnings FATAL => 'all';
use Moo;


use NGNMS::Net::Emulator::Session;
use NGNMS::Net::Emulator::Cisco;
use NGNMS::Net::Emulator::Juniper;

use Module::Runtime qw[ compose_module_name ];

has session=>(
      is => 'rw',
    );

my $host;
sub BUILD {
    my $self = shift;
    my $params = shift;
    Moo::Role->apply_roles_to_object($self,'NGNMS::Net::Emulator::Juniper') if $params->{type} eq 'Juniper';
    Moo::Role->apply_roles_to_object($self,'NGNMS::Net::Emulator::Cisco') if $params->{type} eq 'Cisco';

#    Emsgd::diag($params);
    my $sess_params = {
            'type' => $params->{type} || 'Cisco',
            play_dir =>$params->{reply_dir} || $ENV{"NGNMS_DATA"},

        };
    $sess_params->{'reply'} =  $params->{reply} if  $params->{reply};
    $self->session ( NGNMS::Net::Emulator::Session->new( $sess_params ));


}



1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
