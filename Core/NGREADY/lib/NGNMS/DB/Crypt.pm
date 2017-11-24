package NGNMS::DB::Crypt;

use strict;
use warnings FATAL => 'all';
use Moo::Role;
use MIME::Base64;
use Crypt::TripleDES;
use Emsgd qw(diag);
with "NGNMS::DB::Base";
with "NGNMS::Log4Role";
# -----------------------------------      CRYPT           --------------------------------------------------------
#=for getSettings ($attr_name)
#returns  encrypted value for general $attr_name
#
#=cut

has 'CriptoKey' => (
        is      => 'lazy',
        builder => sub{
            my $self = shift;
            my $rref = $self->dbh->selectcol_arrayref("SELECT value FROM general_settings WHERE name='chiave'");

            return  $rref ? $rref->[0] : undef;
        },
        reader  => 'getCriptoKey'
    );
sub getSettings {
    my $self = shift;
    my $attr_name = shift;
    my $rref = $self->dbh->selectcol_arrayref("SELECT value FROM general_settings WHERE name=?", undef, ($attr_name));
    return  $rref ? $rref->[0] : undef;
}
#sub getCriptoKey() {
#
#}

sub decryptAttrvalue {
    my $self = shift;
    my $pass = shift;
    my $text = shift;
    my $des = Crypt::TripleDES->new();
    my $plaintext = $des->decrypt3 (decode_base64($text), $pass);
    if (defined($plaintext)) {
        $plaintext =~ s/^\s+//;            # no leading white
        $plaintext =~ s/\s+$//;            # no trailing white
    }
    return $plaintext;
}
sub decode_val_from_DB($) {
    my $self = shift;
    my $key = shift;
    my $val = $self->getSettings($key);
    return undef unless $val;

    my $criptokey = $self->getCriptoKey();
    my $p = 48 - length($criptokey);
    my $suffix = ('0' x $p);
    $criptokey .= $suffix;

    #    print "Decrypt $key \n";
    $val =~ s/^\s+//;            # no leading white
    $val =~ s/\s+$//;            # no trailing white

    return $self->decryptAttrvalue($criptokey, $val);

}
=method
=cut
sub getCommunityById {
    my ( $self, $comm_id) = (shift, shift);
    #@inject PGSQL
    my $SQL =
        "
        SELECT community_ro,community_rw
          from ngnms.public.snmp_access
          where id = ?

        ";
    my $rref = $self->dbh->selectrow_hashref($SQL, { lice => {}  }, ($comm_id));
    return $rref;
}

=method
=cut
sub getAccessById {
    # href ($id)
    my ( $self, $acc_id) = (shift, shift);
    #@inject PGSQL
    my $SQL =
        "
        (SELECT
          lower(ar.name) AS attr_name ,
          av.value AS attr_value
          FROM  access a
          JOIN  access_type at ON(at.id = a.id_access_type)
          JOIN attr_access aa ON (at.id=aa.id_access_type)
          JOIN attr ar ON (aa.id_attr = ar.id)
          JOIN attr_value av ON (av.id_attr_access = aa.id AND av.id_access = a.id)
          WHERE
          a.id = ?
      ) UNION ALL   ( SELECT
                    'transport' AS attr_name,
                    at.name
        FROM  access a
        JOIN  access_type at ON(at.id = a.id_access_type)
        WHERE
        a.id = ?
        )

        ";

    my $rref = $self->dbh->selectall_arrayref($SQL, { Slice => {} }, ($acc_id, $acc_id));
    my %struct = map {$_->{'attr_name'} => $_->{'attr_value'}} @{$rref};
    return \%struct
}


sub getRouterAccess {
    my $self = shift;
    my $rt_id = shift;
    #@inject PGSQL
    my $SQL = "
    (SELECT

        lower(ar.name) AS attr_name ,
        av.value AS attr_value
        FROM router_access ra
        JOIN  access a ON (a.id= ra.id_access)
        JOIN  access_type at ON(at.id = a.id_access_type)
        JOIN attr_access aa ON (at.id=aa.id_access_type)
        JOIN attr ar ON (aa.id_attr = ar.id)
        JOIN attr_value av ON (av.id_attr_access = aa.id AND av.id_access = a.id)
        WHERE
        ra.id_router = ?
    )    UNION ALL   ( SELECT
                    'transport' AS attr_name,
                    at.name
        FROM router_access ra
        JOIN  access a ON (a.id= ra.id_access)
        JOIN  access_type at ON(at.id = a.id_access_type)
        WHERE
        ra.id_router = ?
        )
    ";
    my $rref = $self->dbh->selectall_arrayref($SQL, { Slice => {} }, ($rt_id, $rt_id));
    my %struct = map {$_->{'attr_name'} => $_->{'attr_value'}} @{$rref};
    #    diag \%struct;
    my $res = $self->_processJumpHost(\%struct);
    return $res;

}

sub _processJumpHost {
    my ($self, $access_ref) = (shift, shift);
    return $access_ref unless $access_ref && exists $access_ref->{wrappedaccess};
    my $id = $self->decryptAttrvalue($self->getCriptoKey(), $access_ref->{wrappedaccess});
    $self->logger->logdie("JumpHOst misconfigured: no wrapped Access method found") unless $id;
    my $router_method = $self->getAccessById($id);
    $router_method->{jumphost} = $access_ref;
    return $router_method;
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
