package Net::CLI::Interact::Role::Iterator;
{
  $Net::CLI::Interact::Role::Iterator::VERSION = '2.143070';
}

use Moo::Role;
use Sub::Quote;
use MooX::Types::MooseLike::Base qw(ArrayRef Any Int);

has '_sequence' => (
    is => 'rw',
    isa  => ArrayRef[Any],
    required => 1,
);

# fiddly only in case of auto_deref
sub count { return scalar @{ (shift)->_sequence } }

sub first { return (shift)->_sequence->[0]  }
sub last  { return (shift)->_sequence->[-1] }

sub item_at {
    my ($self, $pos) = @_;
    die "position is past the end of sequence\n"
        if $pos >= $self->count;
    return $self->_sequence->[$pos];
}

sub insert_at {
    my ($self, $pos, @rest) = @_;
    my @seq = @{ $self->_sequence };
    splice @seq, $pos, 0, @rest;
    $self->_sequence( \@seq );
}

sub append {
    my $self = shift;
    $self->insert_at( $self->count, @{ (shift)->_sequence } );
}

has '_position' => (
    is => 'rw',
    isa => Int,
    default => quote_sub('-1'),
);

sub idx {
    my $self = shift;
    my $pos = $self->_position;
    die "attempt to read iter index before pulling a value\n"
        if scalar @_ == 0 and $pos == -1;
    $self->_position(shift) if scalar @_;
    return $pos;
}

sub next {
    my $self = shift;
    die "er, please check has_next before next\n"
        if not $self->has_next;

    my $position = $self->_position;
    die "fell off end of iterator\n"
        if ++$position == $self->count;

    $self->_position($position);
    return $self->_sequence->[ $position ];
}

sub has_next {
    my $self = shift;
    return ($self->_position < ($self->count - 1));
}

sub peek {
    my $self = shift;
    return $self->_sequence->[ $self->_position + 1 ]
        if $self->has_next;
}

sub reset { (shift)->_position(-1) }

1;

# ABSTRACT: Array-based Iterator


__END__
=pod

=head1 NAME

Net::CLI::Interact::Role::Iterator - Array-based Iterator

=head1 VERSION

version 2.143070

=head1 SYNOPSIS

 my $count = $iter->count;
  
 $iter->reset;
 while ( $iter->has_next ) {
    print $iter->next;
 }

=head1 DESCRIPTION

This module implements an array-based iterator which may be mixed-in to add
management of a sequence of elements and processing of that sequence.

The iterator is inspired by L<MooseX::Iterator> but limited to arrays and adds
many other facilities. The following section describes the methods provided by
this class.

=head1 USAGE

The slot used for storing iterator elements is named C<_sequence> and you
should write your consuming class to marshall data into this slot, perhaps via
C<BUILD> or C<init_arg>. For example:

 has '+_sequence' => (
    isa => 'ArrayRef[Thingy]',
    init_arg => 'things',
 );

=head1 INTERFACE

=head2 count

The number of elements currently stored in the iterator. Note that this is of
course not the same as the index of the last item in the iterator (which is
0-based)

=head2 first

Returns the first item in the iterator.

=head2 last

Returns the last item in the iterator.

=head2 item_at( $pos )

Returns the item at the given position in the iterator, or throws an exception
if C<$pos> is past the end of the iterator. The position is 0-based.

=head2 insert_at( $pos, $iter )

Inserts the contents of the passed iterator starting I<at> (not I<after>) the
position given. The passed iterator must also be a consumer of this role. The
position is 0-based.

=head2 append( $iter )

Shorthand for C<insert_at> when you want to add the contents of the passed
iterator I<after> the end of the sequence.

=head2 idx( $pos? )

Returns the index (0-based) of the current iterator cursor, or sets the
cursor if a position (again, 0-based) is passed.

An exception is thrown if you attempt to read the cursor position before
having read any elements from the iterator, or if the iterator is empty.

=head2 next

Returns the next item in the iterator sequence, and advances the cursor.
Throws an exception if you have already reached the end of the sequence.

=head2 has_next

Returns true if there are further elements to be read from the iterator.

=head2 peek

Returns the next item in the sequence without advancing the position of the
cursor. It returns C<undef> if you are already at the end of the sequence.

=head2 reset

Resets the cursor so you can iterate through the sequence of elements again.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Oliver Gorwits.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

