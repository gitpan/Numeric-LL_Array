# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Numeric-Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 24;
BEGIN { use_ok('Numeric::LL_Array') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

sub format_array ($);
sub format_array ($) {
  my $in = shift;
  return $in unless ref $in;
  die "Not an array reference: `$in'" unless ref $in eq 'ARRAY';
  '[' . (join ', ', map format_array $_, @$in) . ']'
}

my $s = pack "d*", 345..1344;
ok(1, 'array creation');

is(Numeric::LL_Array::d_extract_1($s,0), 345, 'at index=1');
is(Numeric::LL_Array::d_extract_1($s,999), 1344, 'at last index=1');

my $sub_arr = Numeric::LL_Array::d_extract_as_ref($s,3,4,5);
is("@$sub_arr", "348 353 358 363", 'subarray as ref');
my @sub_arr = Numeric::LL_Array::d_extract($s,3,4,5);
is("@sub_arr", "348 353 358 363", 'subarray as array');
is(length(Numeric::LL_Array::duplicate_types()) % 2, 0, 'even len of duplicate_types');

is(Numeric::LL_Array::__a_accessor__d(undef, $s, 0, ""), 345, '0-dim accessor');
# stride/lim=num_of_items
my $form = pack 'i2', 1, 1;
is(Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form), 345, '1-dim accessor, s');
$form = [1,1];
is(Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form), 345, '1-dim accessor/array, s');
$form = pack 'i2', 0, 1;
is(Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form), 345, '1-dim accessor, stride=0, s');
$form = [0, 1];
is(Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form), 345, '1-dim accessor, stride=0/array, s');

$form = pack 'i2', 1, 1;
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form)], [345], '1-dim accessor');
$form = [1,1];
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form)], [345], '1-dim accessor/array');
$form = pack 'i2', 0, 1;
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form)], [345], '1-dim accessor, stride=0');
$form = [0, 1];
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form)], [345], '1-dim accessor, stride=0/array');

$form = pack 'i2', 0, 3;
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form)], [(345)x 3], '1-dim accessor x 3, stride=0');
$form = [0, 3];
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form)], [(345)x 3], '1-dim accessor x 3, stride=0/array');

$form = pack 'i2', 1, 3;
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form)], [345..347], '1-dim accessor x 3');
$form = [1, 3];
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form)], [345..347], '1-dim accessor x 3/array');

$form = pack 'i*', 2, 3;
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form)], [345,347,349], '1-dim accessor, stride=2');
$form = [2, 3];
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 1, $form)], [345,347,349], '1-dim accessor, stride=2/array');

$form = pack 'i*', 2, 3, 1, 2;
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 2, $form)], [[345,347,349],[346,348,350]], '2-dim accessor, stride=2,1');
$form = [2, 3, 1, 2];
is_deeply([Numeric::LL_Array::__a_accessor__d(undef, $s, 2, $form)], [[345,347,349],[346,348,350]], '2-dim accessor, stride=2,1/array');
