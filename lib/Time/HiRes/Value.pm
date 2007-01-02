#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2006 -- leonerd@leonerd.org.uk

package Time::HiRes::Value;

use strict;

use Carp;

use Time::HiRes qw( gettimeofday );
use POSIX qw( floor );

our $VERSION = '0.02';

=head1 NAME

C<Time::HiRes::Value> - a class representing a time value or interval in exact
microseconds

=head1 DESCRIPTION

The C<Time::HiRes> module allows perl to access the system's clock to
microsecond accuracy. However, floating point numbers are not suitable for
manipulating such time values, as rounding errors creep in to calculations
performed on floating-point representations of UNIX time. This class provides
a solution to this problem, by storing the seconds and miliseconds in separate
integer values, in an array. In this way, the value can remain exact, and no
rounding errors result.

=cut

# Internal helper
sub _split_sec_usec($)
{
   my ( $t ) = @_;

   my $negative = 0;
   if( $t =~ s/^-// ) {
      $negative = 1;
   }

   my ( $sec, $usec );

   # Try not to use floating point maths because that loses too much precision
   if( $t =~ m/^(\d+)\.(\d+)$/ ) {
      $sec  = $1;
      $usec = $2;

      # Pad out to 6 digits
      $usec .= "0" while( length( $usec ) < 6 );
   }
   elsif( $t =~ m/^\d+/ ) {
      # Plain integer
      $sec  = $t;
      $usec = 0;
   }
   else {
      croak "Cannot convert string '$t' into a " . __PACKAGE__;
   }

   if( $negative ) {
      if( $usec != 0 ) {
         $sec  = -$sec - 1;
         $usec = 1000000 - $usec;
      }
      else {
         $sec = -$sec;
      }
   }

   return [ $sec, $usec ];
}

=head1 FUNCTIONS

=cut

=head2 $time = Time::HiRes::Value->new( $sec, $usec )

This function returns a new instance of a C<Time::HiRes::Value> object. This
object is immutable, and represents the time passed in to the C<I<$sec>> and
C<I<$usec>> parameters.

If the C<I<$usec>> value is provided then the new C<Time::HiRes::Value> object
will store the values passed directly, which must both be integers. Negative
values are represented in "additive" form; that is, a value of C<-1.5> seconds
would be represented by

 Time::HiRes::Value->new( -2, 500000 );

If the C<I<$usec>> value is not provided, then the C<I<$sec>> value will be
parsed as a decimal string, attempting to match out a decimal point to split
seconds and microseconds. This method avoids rounding errors introduced by
floating-point maths. 

=cut

sub new
{
   my $class = shift;

   my $self;
   if( @_ == 2 ) {
      $self = [@_]; # a clone
   }
   elsif( @_ == 1 ) {
      $self = _split_sec_usec( $_[0] );
   }
   else {
      die "Bad number of elements in \@_";
   }

   return bless $self, $class;
}

=head2 $time = Time::HiRes::Value->now()

This function returns a new instance of C<Time::HiRes::Value> containing the
current system time, as returned by the system's C<gettimeofday()> call.

=cut

sub now
{
   my $class = shift;
   my @now = gettimeofday();
   return $class->new( @now );
}

sub normalise
{
   my $self = shift;

   my $usec = $self->[1] % 1000000;
   $self->[0] += floor($self->[1] / 1000000);
   $self->[1] = $usec;

   return $self;
}

use overload '""'  => \&STRING,
             '0+'  => \&NUMBER,
             '+'   => \&sum,
             '-'   => \&diff,
             '<=>' => \&cmp;

=head1 OPERATORS

Each of the methods here overloads an operator

=cut

=head2 $self->STRING()

=head2 "$self"

This method returns a string representation of the time, in the form

 $sec.$usec

A leading C<-> sign will be printed if the stored time is negative, and the
C<I<$usec>> part will always contain 6 digits.

=cut

sub STRING
{
   my $self = shift;
   if( $self->[0] < 0 && $self->[1] != 0 ) {
      return sprintf( '%d.%06d', $self->[0] + 1, 1000000 - $self->[1] );
   }
   else {
      return sprintf( '%d.%06d', $self->[0], $self->[1] );
   }
}

sub NUMBER
{
   my $self = shift;
   return $self->[0] + ($self->[1] / 1000000);
}

=head2 $self->sum( $other )

=head2 $self + $other

This method returns a new C<Time::HiRes::Value> value, containing the sum of the
passed values. If a string is passed, it will be parsed according to the same
rules as for the C<new()> constructor.

=cut

sub sum
{
   my $self = shift;
   my ( $other ) = @_;

   if( !ref( $other ) || !$other->isa( "Time::HiRes::Value" ) ) {
      $other = _split_sec_usec( $other );
   }

   return Time::HiRes::Value->new( $self->[0] + $other->[0], $self->[1] + $other->[1] )->normalise();
}

=head2 $self->diff( $other )

=head2 $self - $other

This method returns a new C<Time::HiRes::Value> value, containing the difference
of the passed values. If a string is passed, it will be parsed according to
the same rules as for the C<new()> constructor.

=cut

sub diff
{
   my $self = shift;
   my ( $other, $swap ) = @_;

   if( !ref( $other ) || !$other->isa( "Time::HiRes::Value" ) ) {
      $other = _split_sec_usec( $other );
   }

   ( $self, $other ) = ( $other, $self ) if( $swap );

   return Time::HiRes::Value->new( $self->[0] - $other->[0], $self->[1] - $other->[1] )->normalise();
}

=head2 $self->cmp( $other )

=head2 $self <=> $other

This method compares the two passed values, and returns a number that is
positive, negative or zero, as per the usual rules for the C<< <=> >>
operator. If a string is passed, it will be parsed according to the same
rules as for the C<new()> constructor.

=cut

sub cmp
{
   my $self = shift;
   my ( $other ) = @_;

   if( !ref( $other ) || !$other->isa( "Time::HiRes::Value" ) ) {
      $other = _split_sec_usec( $other );
   }

   return $self->[0] <=> $other->[0] ||
          $self->[1] <=> $other->[1];
}

1;

__END__

=head1 SEE ALSO

=over 4

=item *

L<Time::HiRes> - Obtain system timers in resolution greater than 1 second

=head1 AUTHOR

Paul Evans E<lt>leonerd@leonerd.org.ukE<gt>

=back
