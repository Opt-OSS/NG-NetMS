package Net::CLI::Interact::Transport::Loopback;
{
  $Net::CLI::Interact::Transport::Loopback::VERSION = '2.143070';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(InstanceOf);

extends 'Net::CLI::Interact::Transport::Base';

{
    package # hide from pause
        Net::CLI::Interact::Transport::Loopback::Options;

    use Moo;
    extends 'Net::CLI::Interact::Transport::Options';
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

has 'connect_options' => (
    is => 'ro',
    isa => InstanceOf['Net::CLI::Interact::Transport::Loopback::Options'],
    default => sub { {} },
    coerce => quote_sub(
        q{ Net::CLI::Interact::Transport::Loopback::Options->new(@_) if ref '' ne ref $_[0] }),
    required => 1,
);

#sub _which_perl {
#    use Config;
#    $secure_perl_path = $Config{perlpath};
#    if ($^O ne 'VMS')
#        {$secure_perl_path .= $Config{_exe}
#            unless $secure_perl_path =~ m/$Config{_exe}$/i;}
#    return $secure_perl_path;
#}

sub _build_app { return $^X }

sub runtime_options {
    return ('-ne', 'BEGIN { $| = 1 }; print $_, time, "\nPROMPT> ";');
}

1;

# ABSTRACT: Testable CLI connection


__END__
=pod

=head1 NAME

Net::CLI::Interact::Transport::Loopback - Testable CLI connection

=head1 VERSION

version 2.143070

=head1 DECRIPTION

This module provides a wrapped instance of Perl which simply echoes back any
input provided. This is used for the L<Net::CLI::Interact> test suite.

=head1 INTERFACE

=head2 app

Defaults to the value of C<$^X> (that is, Perl itself).

=head2 runtime_options

Returns Perl options which turn it into a CLI emulator:

 -ne 'BEGIN { $| = 1 }; print $_, time, "\nPROMPT>\n";'

For example:

 some command
 some command
 1301578196
 PROMPT>

In this case the output command was "some command" which was echoed, followed
by the dummy command output (epoch seconds), followed by a "prompt".

=head1 COMPOSITION

See the following for further interface details:

=over 4

=item *

L<Net::CLI::Interact::Transport::Base>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

