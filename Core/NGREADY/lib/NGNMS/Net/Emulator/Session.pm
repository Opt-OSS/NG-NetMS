package NGNMS::Net::Emulator::Session ;
use strict;
use warnings FATAL => 'all';
use Moo;
use File::Slurp;
use Try::Tiny;
use Emsgd qw(diag);
with "NGNMS::Net::SessionRole";
with "NGNMS::Log4Role";

sub connect {
    my $self = shift;
    my $params = shift;
    return 'ok';
}
sub begin_privileged {
    return 1;
}

sub cmd  {
    my ($self, $macro) = @_;
    return undef unless $self->reply && $self->reply->{$macro}; ##no critic (ProhibitExplicitReturnUndef)
    return $self->reply->{$macro};
}

sub macro {
    my ($self, $macro,$params) = @_;
    my $macro_cached_name = $macro;
    if (defined $params->{params}){
        #join params
        $macro_cached_name = $macro.'_'.join('_',@{$params->{params}});
    }
    #make cache-key file-name safe
    $macro_cached_name =~ s/[^A-Za-z0-9\-\.]/\_/g;
    if ($self->reply && $self->reply->{$macro}) {
        $self->logger->debug("emulating $macro from ".$self->reply_dir.'/'.$self->reply->{$macro});
        return File::Slurp::read_file($self->reply_dir.'/'.$self->reply->{$macro}) if (-f $self->reply_dir.'/'.( split /\n/, $self->reply->{$macro})[0]);
        return $self->reply->{$macro};
    }
    $self->logger->debug("emulating $macro from ".$self->play_dir.'/'.$macro_cached_name.'.txt');
    return File::Slurp::read_file($self->play_dir.'/'.$macro_cached_name.'.txt') if $self->play_dir && (-f $self->play_dir.'/'.$macro_cached_name.'.txt');
    return undef ##no critic (ProhibitExplicitReturnUndef)
}
sub execute_chained_macro {
    my $self = shift;
    my @chained_commands = @_;
    #    diag \@chained_commands;
    my $res;
    for my $macro (@chained_commands) {
        $res .= $self->macro( $macro );
    }
    return $res;
}
sub check_is_privileged {
    return 1;
}

1;