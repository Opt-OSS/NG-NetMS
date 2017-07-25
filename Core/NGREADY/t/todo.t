use warnings FATAL => 'all';
use strict;
use AutoLoader qw/AUTOLOAD/;
use Emsgd;
use Test::More ; #for syntax only
use Test::Subroutines;
use Test::Spec ;

xdescribe 'Cisco' => sub {
        xit 'should trim eq_typ (C1 ciscoMC3810     )';
    };
xdescribe 'Juniper' => sub {
        xit 'should use PhraseBook';
    };
ok 1;
runtests unless caller;