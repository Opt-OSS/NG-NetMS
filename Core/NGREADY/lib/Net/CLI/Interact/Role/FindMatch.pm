package Net::CLI::Interact::Role::FindMatch;
{
  $Net::CLI::Interact::Role::FindMatch::VERSION = '2.143070';
}

use Moo::Role;

# see if any regexp in the arrayref match the response
sub find_match {
    my ($self, $text, $matches) = @_;
    $matches = ((ref $matches eq ref qr//) ? [$matches] : $matches);
    return undef unless
        (scalar grep {ref $_ eq ref qr//} @$matches) == scalar @$matches;

    use List::Util 'first';
    return first { $text =~ $_ } @$matches;
}


1;
