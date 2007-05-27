#!/usr/bin/perl -w

use strict;
use Test::More tests => 50;
use Test::Exception;

use Time::HiRes::Value;

use Carp ();

dies_ok( sub { Time::HiRes::Value->new( "Hello" ); }, 
         'Exception (not convertable)' );
dies_ok( sub { Time::HiRes::Value->new( "15.pineapple" ); },
         'Exception (not convertable, leading digits)' );
dies_ok( sub { Time::HiRes::Value->new( "hello", "world" ); },
         'Exception (not convertable pair)' );

my $t1 = Time::HiRes::Value->new( 1 );
ok( defined $t1, 'defined $t1' );
is( ref $t1, "Time::HiRes::Value", 'ref $t1' );

is( "$t1", "1.000000", 'Stringify' );
is( ref( $t1->NUMBER ), "", 'Numerify returns plain scalar' );

my $neg = Time::HiRes::Value->new( -4 );
is( "$neg", "-4.000000", 'Stringify negative' );

is( $neg + 2, "-2.000000", 'Negative two' );
is( $neg + 3, "-1.000000", 'Negative one' );
is( $neg + 3.5, "-0.500000", 'Negative half' );
is( $neg + 4, "0.000000", 'Negative four + four = zero' );

$neg = Time::HiRes::Value->new( -4.1 );
is( "$neg", "-4.100000", 'Stringify negative non-integer' );

my $t2 = Time::HiRes::Value->new( 1.5 );
is( "$t2", "1.500000", 'Non-integer constructor' );

my $t3 = Time::HiRes::Value->new( 2, 500 );
is( "$t3", "2.000500", 'Array' );

cmp_ok( $t1, '==', 1, 'Compare == scalar 1' );
cmp_ok( $t1, '<=', 2, 'Compare <= scalar 2' );
cmp_ok( $t2, '==', 1.5, 'Compare == scalar 1.5' );
cmp_ok( $t2, '!=', 1.6, 'Compare != scalar 1.6' );

cmp_ok( $t1, '!=', $t3, 'Compare != Value3' );
cmp_ok( $t3, '>', $t2, 'Compare > Value2' );

my $t4 = $t1 + 1;
is( "$t4", "2.000000", 'add scalar 1' );
$t4 = $t2 + 2.3;
is( "$t4", "3.800000", 'add scalar 2.3' );
$t4 = 1 + $t1;
is( "$t4", "2.000000", 'add scalar 1 swapped' );

$t4 = $t1 + -1;
is( "$t4", "0.000000", 'inverse of addition' );

$t4 = $t1 + $t2;
is( "$t4", "2.500000", 'add Value2' );

cmp_ok( $t1 + 0, '==', $t1, 'identity of addition' );
cmp_ok( $t1 + 3, '==', 3 + $t1, 'commutativity of addition' );

$t4 = $t3 - 2;
is( "$t4", "0.000500", 'subtract scalar 2' );
$t4 = 4 - $t2;
is( "$t4", "2.500000", 'subtract scalar 4 swapped' );

$t4 = $t1 - 3.1;
is( "$t4", "-2.100000", 'subtract scalar 3.1, negative result' );

cmp_ok( $t1 - 0, '==', $t1, 'identity of subtraction' );

is( $t1 * 1, "1.000000", 'multiply t1 * 1' );
is( $t1 * 250, "250.000000", 'multiply t1 * 250' );

is( $t2 * 2, "3.000000", 'multiply t2 * 2' );
is( $t2 * 4.2, "6.300000", 'multiply t2 * 4.2' );
is( $t2 * -4.2, "-6.300000", 'multiply t2 * -4.2' );

cmp_ok( $t1 * 1, '==', $t1, 'identity of multiplication' );
cmp_ok( $t1 * 3, '==', 3 * $t1, 'commutativity of multiplication' );

cmp_ok( $t1 * 0, '==', 0, 'nullability of multiplication' );

dies_ok( sub { $t1 * $t2 },
         'multiply t1 * t2 fails' );

is( $t1 / 1, "1.000000", 'divide t1 / 1' );
is( $t1 / 20, "0.050000", 'divide t1 / 20' );

is( $t2 / 2, "0.750000", 'divide t2 / 2' );
is( $t2 / 1.5, "1.000000", 'divide t2 / 1.5' );
is( $t2 / -4, "-0.375000", 'divide t2 / -4' );

cmp_ok( $t1 / 1, '==', $t1, 'identity of division' );

dies_ok( sub { 15 / $t1 },
         'divide 15 / t1 fails' );
dies_ok( sub { $t1 / $t2 },
         'divide t1 / t2 fails' );

# Make sure Carp doesn't eat our message
$Carp::CarpInternal{'Time::HiRes::Value'} = 1;
$Carp::CarpInternal{'Test::Exception'} = 1;

# Ensure division by zero appears to come from the right place
throws_ok( sub { $t1 / 0 },
           qr/^Illegal division by zero at $0 line/,
           'divide t1 / 0 fails' );
