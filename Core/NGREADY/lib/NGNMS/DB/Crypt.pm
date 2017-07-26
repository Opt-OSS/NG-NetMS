package NGNMS::DB::Crypt;

use strict;
use warnings FATAL => 'all';
use Moo::Role;
use MIME::Base64;
use Crypt::TripleDES;
use Emsgd qw(diag);
with "NGNMS::DB::Base";
# -----------------------------------      CRYPT           --------------------------------------------------------
#=for getSettings ($attr_name)
#returns  encrypted value for general $attr_name
#
#=cut

sub getSettings {
    my $self = shift;
    my $attr_name = shift;
    my $rref = $self->dbh->selectcol_arrayref( "SELECT value FROM general_settings WHERE name=?",undef,($attr_name) );
    return  $rref ? $rref->[0] : undef;
}
sub getCriptoKey() {
    my $self = shift;
    my $rref = $self->dbh->selectcol_arrayref( "SELECT value FROM general_settings WHERE name='chiave'" );

    return  $rref ? $rref->[0] : undef;
}

sub decryptAttrvalue
{
    my $self = shift;
    my $pass = shift;
    my $text = shift;
    my $des = Crypt::TripleDES->new();
    my $plaintext = $des->decrypt3 ( decode_base64( $text ), $pass );
    if (defined( $plaintext ))
    {
        $plaintext =~ s/^\s+//;            # no leading white
        $plaintext =~ s/\s+$//;            # no trailing white
    }
    return $plaintext;
}
sub decode_val_from_DB($){
    my $self = shift;
    my $key = shift;
    my $val = $self->getSettings( $key  );
    return undef unless $val;

    my $criptokey = $self->getCriptoKey();
    my $p = 48 - length($criptokey);
    my $suffix = ( '0' x $p );
    $criptokey .= $suffix;

    #    print "Decrypt $key \n";
    $val =~ s/^\s+//;            # no leading white
    $val =~ s/\s+$//;            # no trailing white

    return $self->decryptAttrvalue( $criptokey, $val );

}
#=for DB_getRouterAccess
#    GET data to access router
#    Param : router name
#
#=cut
sub getRouterAccess($) {
    my $self = shift;
    my $rt_id = shift;
    my $SQL = "
    select
        at.name as access_type,
        r.eq_vendor as vendor,
        ar.name as attr_name ,
        av.value as attr_value
        from router_access ra
        join routers r on (r.router_id = ra.id_router)
        join  access a on (a.id= ra.id_access)
        join  access_type at on(at.id = a.id_access_type)
        join attr_access aa on (at.id=aa.id_access_type)
        join attr ar on (aa.id_attr = ar.id)
        join attr_value av on (av.id_attr_access = aa.id and av.id_access = a.id)
        where
        ra.id_router = ?
    ";

    my $rref = $self->dbh->selectall_arrayref( $SQL,undef,($rt_id) );
    ##	print "data:\n";
    ##    print Dumper($rref->[0]);
    return $rref;
}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
