package NGNMS::Net::Nmap;

use strict;
use warnings FATAL => 'all';
use Nmap::Scanner;

sub getNmapResponse
{
    my $addr = shift;
    my $scanner = Nmap::Scanner->new;

    $scanner->add_target( $addr );
    my $results = $scanner->scan('-sn -PS22,23,161 '.$addr);
    my $host_list = $results->get_host_list();
    my $counter = 0;

    while (my $host = $host_list->get_next()) {
        unless (!($host->addresses)[0]->addr) {
            if ($host->status eq 'up') {
                $counter++;
            }
        }
    }

    return $counter;
}

1;
# ABSTRACT: This file is part of open source NG-NetMS tool.
