# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Numeric-Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict;
use Test::More tests => 10 ;

BEGIN { use_ok('Numeric::LL_Array',
 qw( packId_d packId_s access_d access_s dd2d2_modf ds2d2_frexp dd2d2_frexp)) };

my $d   = pack packId_d, my $f  = 8904625e-3;	# 5**3 * 71237 - exactly representable
my $dd  = pack packId_d, 0;
my $ss  = pack packId_s, 0;
my $res = pack packId_d, 0;

dd2d2_modf($d, $dd, $res, 0, 0, 0, 0, "", "", "");
ok(1, "finished modf($f)");
is_deeply(access_d($res), .625, "... fractional part correct");
is_deeply(access_d($dd), 8904, "... integer part correct");

ds2d2_frexp($d, $ss, $res, 0, 0, 0, 0, "", "", "");
ok(1, "finished frexp($f), short exponent");
is_deeply(access_d($res), 0.54349517822265625, "... mantissa correct");
is_deeply(access_s($ss), 14, "... exponent correct");

dd2d2_frexp($d, $dd, $res, 0, 0, 0, 0, "", "", "");
ok(1, "finished frexp($f), double exponent");
is_deeply(access_d($res), 0.54349517822265625, "... mantissa correct");
is_deeply(access_d($dd), 14, "... exponent correct");

