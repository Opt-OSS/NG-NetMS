#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use NGNMS::App;
use Emsgd qw (diag);

my $app = NGNMS::App->instance;
$app->run();

