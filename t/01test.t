#!/usr/bin/perl -w

use strict;
use Test::More tests => 22;
use Test::Exception;

use Time::HiRes::Value;

dies_ok( sub { Time::HiRes::Value->new( "Hello" ); }, 
         'Exception (not convertable)' );

my $t1 = Time::HiRes::Value->new( 1 );
ok( defined $t1, 'defined $t1' );
is( ref $t1, "Time::HiRes::Value", 'ref $t1' );

is( "$t1", "1.000000", 'Stringify' );

my $neg = Time::HiRes::Value->new( -4 );
is( "$neg", "-4.000000", 'Stringify negative' );

$neg = Time::HiRes::Value->new( -4.1 );
is( "$neg", "-4.100000", 'Stringify negative non-integer' );

my $t2 = Time::HiRes::Value->new( 1.5 );
is( "$t2", "1.500000", 'Non-integer constructor' );

my $t3 = Time::HiRes::Value->new( 2, 500 );
is( "$t3", "2.000500", 'Array' );

# is can't directly do this comparision
is( $t1 == 1, 1, 'Compare eq scalar 1' );
is( $t1 > 2, '', 'Compare gt scalar 2' );
is( $t2 == 1.5, 1, 'Compare eq scalar 1.5' );
is( $t2 == 1.6, '', 'Compare eq scalar 1.6' );

is( $t1 != $t3, 1, 'Compare ne Value3' );
is( $t3 > $t2, 1, 'Compare gt Value2' );

my $t4 = $t1 + 1;
is( "$t4", "2.000000", 'add scalar 1' );
$t4 = $t2 + 2.3;
is( "$t4", "3.800000", 'add scalar 2.3' );
$t4 = 1 + $t1;
is( "$t4", "2.000000", 'add scalar 1 swapped' );

$t4 = $t1 + -1;
is( "$t4", "0.000000", 'identity of addition' );

$t4 = $t1 + $t2;
is( "$t4", "2.500000", 'add Value2' );

$t4 = $t3 - 2;
is( "$t4", "0.000500", 'subtract scalar 2' );
$t4 = 4 - $t2;
is( "$t4", "2.500000", 'subtract scalar 4 swapped' );

$t4 = $t1 - 3.1;
is( "$t4", "-2.100000", 'subtract scalar 3.1, negative result' );
