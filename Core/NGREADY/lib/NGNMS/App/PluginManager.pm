package NGNMS::App::PluginManager;

use strict;
use Emsgd qw /diag/;
use warnings FATAL => 'all';
use Moo;
use MooX::Options;
use Module::Pluggable search_path => 'NGNMS::Plugins', require => 1;
use NGNMS::App::PollHostPluginInterface;
with   "NGNMS::App::Database";
#
#=for main
#
#find all pollhost plugin
#
#=cut
sub find_pollhost_plugins{
    my $self = shift;
    my @pollHostPlugins = (); #clear array so no duplicates
    #**
    #  $self->plugins - list of modules returned by Module::Pluggable with search_path => 'NGNMS::Plugins'
    #**
    foreach my NGNMS::App::PollHostPluginInterface $plugin ($self->plugins) {
        push ( @pollHostPlugins, $plugin->new)
            if $plugin->can( 'checkCanPollHost' ) && $plugin->checkCanPollHost() && !Moo::Role->is_role( $plugin );
    }
    diag (\@pollHostPlugins);
    diag $pollHostPlugins[0]->getModuleName();
}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
