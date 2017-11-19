package Net::CLI::Interact::Logger;
{
  $Net::CLI::Interact::Logger::VERSION = '2.143070';
}

use Moo;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(HashRef Bool ArrayRef Any);

use Class::Mix qw(genpkg);
use Time::HiRes qw(gettimeofday tv_interval);
use Log::Dispatch::Config; # loads Log::Dispatch
use Log::Dispatch::Configurator::Any;

sub BUILDARGS {
    my ($class, @args) = @_;

    # accept single hash ref or naked hash
    my $params = (ref {} eq ref $args[0] ? $args[0] : {@args});

    # back-compat for old attr name
    $params->{log_stamp} = $params->{log_stamps} if exists $params->{log_stamps};

    return $params;
}

has log_config => (
    is => 'rw',
    isa => HashRef,
    builder => 1,
    trigger => quote_sub(q{ $_[0]->_clear_logger }),
);

sub _build_log_config {
    return {
        dispatchers => ['screen'],
        screen => {
            class => 'Log::Dispatch::Screen',
            min_level => 'debug',
        },
    };
}

has _logger => (
    is => 'ro',
    isa => quote_sub(q{ $_[0]->isa('Log::Dispatch::Config') }),
    builder => 1,
    lazy => 1,
    clearer => 1,
);

# this allows each instance of this module to have its own
# wrapped logger with different configuration.
sub _build__logger {
    my $self = shift;

    my $anon_logger = genpkg();
    {
        no strict 'refs';
        @{"$anon_logger\::ISA"} = 'Log::Dispatch::Config';
    }

    my $config = Log::Dispatch::Configurator::Any->new($self->log_config);
    $anon_logger->configure($config);

    return $anon_logger->instance;
}

has 'log_stamp' => (
    is => 'rw',
    isa => Bool,
    default => quote_sub('1'),
);

has 'log_category' => (
    is => 'rw',
    isa => Bool,
    default => quote_sub('1'),
);

has 'log_start' => (
    is => 'ro',
    isa => ArrayRef,
    default => sub{ [gettimeofday] },
);

has 'log_flags' => (
    is => 'rw',
    isa => Any, # FIXME 'ArrayRef|HashRef[Str]',
    default => sub { {} },
);

my %code_for = (
    debug     => 0,
    info      => 1,
    notice    => 2,
    warning   => 3,
    error     => 4,
    critical  => 5,
    alert     => 6,
    emergency => 7,
);

sub would_log {
    my ($self, $category, $level) = @_;
    return 0 if !defined $category or !defined $level;

    my $flags = (ref $self->log_flags eq ref []
        ? { map {$_ => 'error'} @{$self->log_flags} }
        : $self->log_flags
    );

    return 0 if !exists $code_for{$level};
    return 0 if !exists $flags->{$category};
    return ($code_for{$level} >= $code_for{ $flags->{$category} });
}

sub log {
    my ($self, $category, $level, @msgs) = @_;
    return unless $self->would_log($category, $level);
    @msgs = grep {defined} @msgs;
    return unless scalar @msgs;

    my $prefix = '';
    $prefix .= sprintf "[%11s] ", sprintf "%.6f", (tv_interval $self->log_start, [gettimeofday])
        if $self->log_stamp;
    $prefix .= (substr $category, 0, 2)
        if $self->log_category;

    my $suffix = '';
    $suffix = "\n" if $msgs[-1] !~ m/\n$/;

    $self->_logger->$level($prefix . (' ' x (2 - $code_for{$level})), (join ' ', @msgs) . $suffix);
}

1;

# ABSTRACT: Per-instance multi-target logging, with categories


__END__
=pod

=head1 NAME

Net::CLI::Interact::Logger - Per-instance multi-target logging, with categories

=head1 VERSION

version 2.143070

=head1 SYNOPSIS

 $logger->log($category, $level, @message);

=head1 DESCRIPTION

This module implements a generic logging service, based on L<Log::Dispatch>
but with additional options and configuration. Log messages coming from your
application are categorized, and each category can be enabled/disabled
separately and have its own log level (i.e. C<emergency> .. C<debug>). High
resolution timestamps can be added to log messages.

=head1 DEFAULT CONFIGURATION

Being based on L<Log::Dispatch::Config>, this logger can have multiple
targets, each configured for independent level thresholds. The overall default
configuration is to print log messages to the screen (console), with a minimum
level of C<debug>. Each category (see below) has its own log level as well.

Note that categories, as discussed below, are arbitrary so if a category is
not explicitly enabled or disabled, it is assumed to be B<disabled>. If you
wish to invent a new category for your application, simply think of the name
and begin to use it, with a C<$level> and C<@message> as above in the
SYNOPSIS.

=head1 INTERFACE

=head2 log( $category, $level, @message )

The combination of category and level determine whether the the log messages
are emitted to any of the log destinations. Destinations are set using the
C<log_config> method, and categories are configured using the C<log_flags>
method.

The C<@message> list will be joined by a space character, and a newline
appended if the last message doesn't contain one itself. Messages are
prepended with the first character of their C<$category>, and then indented
proportionally to their C<$level>.

=head2 log_config( \%config )

A C<Log::Dispatch::Config> configuration (hash ref), meaning multiple log
targets may be specified with different minimum level thresholds. There is a
default configuration which emits messages to your screen (console) with no
minimum threshold:

 {
     dispatchers => ['screen'],
     screen => {
         class => 'Log::Dispatch::Screen',
         min_level => 'debug',
     },
 };

=head2 log_flags( \@categories | \%category_level_map )

The user is expected to specify which log categories they are interested in,
and at what levels. If a category is used in the application for logging but
not specified, then it is deemed B<disabled>. Hence, even though the default
destination log level is C<debug>, no messages are emitted until a category is
enabled.

In the array reference form, the list should contain category names, and they
will all be mapped to the C<error> level:

 $logger->log_flags([qw/
     network
     disk
     io
     cpu
 /]);

In the hash reference form, the keys should be category names and the values
log levels from the list below (ordered such that each level "includes" the
levels I<above>):

 emergency
 alert
 critical
 error
 warning
 notice
 info
 debug

For example:

 $logger->log_flags({
     network => 'info',
     disk    => 'debug',
     io      => 'critical',
     cpu     => 'debug',
 });

Messages at or above the specified level will be passed on to the
C<Log::Dispatch> target, which may then specify an overriding threshold.

=head2 C< Net::CLI::Interact->default_log_categories() >>

Not a part of this class, but the only way to retrieve a list of the current
log categories used in the L<Net::CLI::Interact> distribution source. Does not
take into account any log categories added by the user.

=head2 log_stamp( $boolean )

Enable (the default) or disable the display of high resolution interval
timestamps with each log message.

=head2 log_category( $boolean )

Enable (the default) or disable the display of the first letters of the
category name with each log message.

=head2 log_start( [$seconds, $microseconds] )

Time of the start for generating a time interval when logging stamps. Defaults
to the result of C<Time::HiRes::gettimeofday> at the point the module is
loaded, in list context.

=head2 would_log( $category, $level )

Returns True if, according to the current C<log_flags>, the given C<$category>
is enabled at or above the threshold of C<$level>, otherwise returns False.
Note that the C<Log::Dispatch> targets maintain their own thresholds as well.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

