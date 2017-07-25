package NGNMS::Scheduler::SchedulerRole;
use strict;
use warnings FATAL => 'all';
use Moo::Role;
use Config::Crontab;
use Digest::MD5 qw(md5_hex);
use File::Slurp;

use Emsgd qw/diag/;
with "NGNMS::Log4Role";
#@returns NGNMS::DB
has DB => (            is => 'ro'    );
has dbhost => (        is => 'ro'    );
has dbport => (        is => 'ro'    );
has dbname => (        is => 'ro'    );
has dbuser => (        is => 'ro'    );
has dbpassword => (    is => 'ro'    );
has ngnms_user => (    is => 'ro'    );
has crontab_key => (is => 'rw', required => 1);
has exec_file  => (is => 'rw', required => 1);
has crontab => (is => 'ro', lazy => 1, builder => 1);

sub _build_crontab {
    my $self = shift;
    return Config::Crontab->new( -owner => $self->ngnms_user );
}
sub _get_current_schedule{
    my $self = shift;
    $self->crontab->read;
    return $self->crontab->block( $self->crontab->select( -type => "comment", -data_re => $self->crontab_key ) );
}
sub __save{
    my $self = shift;

    my ($newblock, $oldblock) = @_;
    if (defined $oldblock)
    {
        ## update block in crontab
        $self->crontab->replace( $oldblock, $newblock );
        ## write changes in crontab
        $self->crontab->write;
    }
    else
    {
        ## add this block to crontab file
        $self->crontab->last( $newblock );
        ## write out crontab file
        $self->crontab->write;
    }
}
sub save{
    my $self = shift;
    my $schedule = shift;


    ## Open crontab for user ngnms
    ## read crontab
    $self->crontab->read;
    ## create an array of crontab objects
    my @lines = (
        Config::Crontab::Comment->new(-data => $self->crontab_key),
        Config::Crontab::Event->new(-data => "$schedule $self->{exec_file}")
    );
    ## create a block object via lines attribute
    my $newblock = Config::Crontab::Block->new( -lines => \@lines );
    my $oldblock = $self->_get_current_schedule;
    return 0 if $oldblock && $oldblock->dump eq $newblock->dump;

    $self->__save($newblock, $oldblock);
    return 1;

}
sub remove {
    my $self = shift;
    my $oldblock = $self->_get_current_schedule;
    if (defined $oldblock)
    {
        ## remove this block from the crontab
        $self->crontab->remove( $oldblock );
        ## write changes in crontab
        $self->crontab->write;
    }
}

sub update_file{
    my $self = shift;
    my $file_content = shift;
    my $new_chksum = Digest::MD5::md5_hex($file_content);
    my $old_file_content = File::Slurp::read_file($self->exec_file, err_mode => 'quiet');
    unless (defined $old_file_content and $new_chksum eq md5_hex($old_file_content)) {
        $self->logger->info("Updating $self->{exec_file}");
        File::Slurp::write_file($self->exec_file, $file_content);
        chmod 0775, $self->exec_file;
        return 1;
    }
    return 0;

}
1;