package passwds;

use strict;

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %host_passwds);

@ISA = qw(Exporter AutoLoader);

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK   = qw(%host_passwds);

# Add more lines like that
# @{$host_passwds{'host'}} = ( "", "passwd", "en_passwd" );
# @{$host_passwds{'host'}} = ( "user", "passwd", "en_passwd" );
#


__END__
