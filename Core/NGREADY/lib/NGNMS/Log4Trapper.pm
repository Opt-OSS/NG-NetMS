package NGNMS::Log4Trapper;

use strict;

use warnings FATAL => 'all';
use Log::Log4perl qw(:easy);




sub TIEHANDLE {
    my $class = shift;
    bless [], $class;
}

sub PRINT {
    my $self = shift;
    $Log::Log4perl::caller_depth++;
    DEBUG @_;
    $Log::Log4perl::caller_depth--;
}
1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
