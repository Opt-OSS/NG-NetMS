package Net::CLI::Interact::Transport::Role::StripControlChars;

use strict;
use warnings FATAL => 'all';

use Moo::Role;

my %ansi_codes = (
    1  => q/\x1b\[\d+;\d+H/, # code_position_cursor
    3  => q/\x1b\[\?25h/, #code_show_cursor
    4  => q/\x1b\x45/, #code_next_line
    5  => q/\x1b\[2K/, #code_erase_line
    6  => q/\x1b\[K/, #code_erase_start_line
    7  => q/\x1b\[\d+;\d+r/, #code_enable_scroll
    68 => q/\e\[\??\d+(;\d+)*[A-Za-z]/, #VLZ addon from ytti/oxidized
);

# https://github.com/ollyg/Net-CLI-Interact/issues/22
around 'buffer' => sub {
    my $orig = shift;
    my $buffer = ($orig->(@_) || '');

    # remove control characters
    $buffer =~ s/[\000-\010\013\014\016-\032\034-\037]//g;

    # strip ANSI terminal codes
    foreach my $code (sort keys %ansi_codes) {
        my $to = '';
        $to = "\n" if ($code == 4); # CODE_NEXT_LINE must substitute with '\n'
        $buffer =~ s/$ansi_codes{$code}/$to/g;
    }

    return $buffer;
};

1;
