#package EscapeANSI;

package NGNMS::EscapeANSI;


use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/escape_ansi/;

use strict;
use warnings;


sub escape_ansi {

    my $buf_ref = shift;

    my %ansi = (
        1  => q/\x1b\x5b\d+A/, #cursor up       $1 lines
        2  => q/\x1b\x5b\d+B/, #cursor down     $1 lines
        3  => q/\x1b\x5b\d+C/, #cursor forward  $1 chars
        4  => q/\x1b\x5b\d+D/, #cursor backward $1 chars
        5  => q/\x1b\x5bK/, #Erase from cursor to end of line
        6  => q/\x1bD/, #index
        7  => q/\x1bM/, #revers index
        8  => q/\x1b7/, #save cursor and attrib
        9  => q/\x1b8/, #restore cursor and attrib
        10 => q/\x1b\x233/, #change this line to double-height top half
        11 => q/\x1b\x234/, #change this line to double height bottom half
        12 => q/\x1b\x235/, #change this line to single-width single height
        13 => q/\x1b\x236/, #change this line to double-width single height
        14 => q/\x1b\x5b\d+\x3b[01457]+m/, #0-no attributes 1-bold 4-underline 5-Blink 7-Reverse
        15 => q/\x1b\x5b\d+\x3b\d+[fH]/, #Direct cursor addr $1 line# - $2 col#
        16 => q/\x1b\x5b0K/, #Same
        17 => q/\x1b\x5b1/, #Erase from beg of line to cursor
        18 => q/\x1b\x5b2K/, #Erase line containing cursor
        19 => q/\x1b\x5bJ/, #Erase from cursor to end of screen
        20 => q/\x1b\x5b0J/, #same
        21 => q/\x1b\x5b2J/, #cls
        22 => q/\x1b\x5b\d\x3b[01234]+q/, #Prog LED's: 0- all off
        23 => q/\x1b[\x28\x29]A/, #UK Char Set
        24 => q/\x1b[\x28\x29]B/, #US Char Set
        25 => q/\x1b[\x28\x29]0/, #Graphic Drawing set|reset
        26 => q/\x1b[\x28\x29]1/, #Alt Char ROM set|reset
        27 => q/\x1b[\x28\x29]2/, #Alt Graphic ROM set|reset
        28 => q/\x1bK\d+\x38\d+r/, #Set top scroll window $1 and bottom scroll window $2
        29 => q/\x1bH/, #Set   tab at current col
        30 => q/\x1b\x5bg/, #clear tab at current col
        31 => q/\x1b\x5b0g/, #same
        32 => q/\x1b\x5b3g/, #clear all tabs
        ### MODES ###
        33 => q/\x1b\x5b20h/, #New Line
        34 => q/\x1b\x5b20l/, #line feed reset
        35 => q/\x1b\x5b\x3f1h/, #cursor Set
        36 => q/\x1b\x5b\x3f1l/, #Cursor reset
        37 => q/\x1b\x5b\x3f2l/, #VT 52
        38 => q/\x1b\x5b\x3f3h/, #132  Colreset
        39 => q/\x1b\x5b\x3f3l/, #80 Col
        40 => q/\x1b\x5b\x3f4h/, #Smooth Scroll
        41 => q/\x1b\x5b\x3f4l/, #Jump Scroll
        42 => q/\x1b\x5b\x3f5h/, #Reverse Screen
        43 => q/\x1b\x5b\x3f5l/, #Normal Screen
        44 => q/\x1b\x5b\x3f6h/, #Rel Origin Mode
        45 => q/\x1b\x5b\x3f6l/, #Abs Origin Mode
        46 => q/\x1b\x5b\x3f7h/, #Wrap On
        47 => q/\x1b\x5b\x3f7l/, #Wrap Off
        48 => q/\x1b\x5b\x3f8h/, #Autorepeat On
        49 => q/\x1b\x5b\x3f8l/, #Autorepeat Off
        50 => q/\x1b\x5b\x3f9h/, #Interface On
        51 => q/\x1b\x5b\x3f9l/, #Interface Off
        ### REPORTS ###
        52 => q/\x1b\x5b6n/, #Report Cursor position
        53 => q/\x1b\x5b\d+\x3b(\d+)R/, #response: cursor at $1-line#$2-col#
        54 => q/\x1b\x5b5n/, #Report Status
        55 => q/\x1b\x5bc/, #response: Terminial OK
        56 => q/\x1b\x5b0c/, #response: Terminial NOT OK
        57 => q/\x1b\x5bc/, #What are you?
        58 => q/\x1b\x5b0c/, #What are you?
        59 => q/\x1b\x5b\x3f1\x3b[0-7]c/, #0-VT100 1-STP 2-AVO 3-AVO/STP 4-GO 5-GO/STP 6-GO/AVO 7-GO/AVO/STP
        60 => q/\x1bc/, #reset
        61 => q/\x1b\x238/, #fill screen with "E"
        62 => q/\x1b\x5b2\x3b\d{1,3}y/, #sum of tests requested ( 1 -pwr up 2- Data loop 4- EIA Modem8-repeat INF)
        63 => q/\x1bA/,
        64 => q/\x1bB/,
        ### VT52 Compatible Modes
        65 => q/\x1b[A-DF-KZ12<>=]/,
        66 => q/\x1bA[\x3e\x3d\x3c]/,
        67 => q/\x1bY[\000-\377]{2}/,
        68 => q/\e\[\??\d+(;\d+)*[A-Za-z]/
        , #VLZ addon from ytti/oxidized  https://github.com/ytti/oxidized/pull/498/commits/fa949e7e7e548a45c2cddbeadee294082ae0799a
    );

=for
Ptytjon NEtmiko
https://github.com/ktbyers/netmiko/blob/47c597a674ac8d7e8a2c18388bfb3dbcb205b273/netmiko/base_connection.py
Remove any ANSI (VT100) ESC codes from the output
        http://en.wikipedia.org/wiki/ANSI_escape_code
        Note: this does not capture ALL possible ANSI Escape Codes only the ones
        I have encountered
        Current codes that are filtered:
        ESC = '\x1b' or chr(27)
        ESC = is the escape character [^ in hex ('\x1b')
        ESC[24;27H   Position cursor
        ESC[?25h     Show the cursor
        ESC[E        Next line (HP does ESC-E)
        ESC[2K       Erase line
        ESC[1;24r    Enable scrolling from start to row end
        HP ProCurve's, Cisco SG300, and F5 LTM's require this (possible others)
=cut

    my %netmiko = (
        1  => q/\x1b\[\d+;\d+H/, # code_position_cursor
        3  => q/\x1b\[\?25h/, #code_show_cursor
        4  => q/\x1b\x45/, #code_next_line
        5  => q/\x1b\[2K/, #code_erase_line
        6  => q/\x1b\[K/, #code_erase_start_line
        7  => q/\x1b\[\d+;\d+r/, #code_enable_scroll
        68 => q/\e\[\??\d+(;\d+)*[A-Za-z]/, #VLZ addon from ytti/oxidized

    );
    foreach(sort keys %netmiko) {
        return unless $$buf_ref;
        my $x = '';
        # CODE_NEXT_LINE must substitute with '\n'
        $x = "\n" if ($_ == 4);  # dito
        $$buf_ref =~ s/$netmiko{$_}/$x/g;
    }

}

1;
__END__

=head1 NAME

EscapeANSI - Remove/Extract ANSI VT52/VT100 Screen Escape Codes

=head1 SYNOPSIS

  use EscapeANSI;

  $socket->recv($buffer, $size);

  escape_ansi(\$buffer);

  print $buffer;

=head1 DESCRIPTION

This module can be used to clean ANSI escape codes for VT52 & VT100 Terminals.

I created this module to intelligently strip out escape codes that are sent
from some Win32 Telnet Servers when using Net::Telnet.  Stripping the codes cleans
up the display and greatly eases the problem of parsing the data.  You can substitute
by code if you like, but I haven't mapped that yet.  I will clean it up later.

escape_ansi is exported


=head1 AUTHOR

Distributed under same license as Perl.
James B. Moosmann <jmoosmann@earthlink.net> Copyright 2002

=cut