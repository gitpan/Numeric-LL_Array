# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Numeric-Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 189;
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
is(length(Numeric::LL_Array::duplicateTypes()) % 2, 0, 'even len of duplicate_types');

my $size_d = $Numeric::LL_Array::typeSizes{d};
#is($size_d, 8, "Architecture-dependent test of size");
Numeric::LL_Array::init_interface('Numeric::LL_Array::access_d_', -1, chr($size_d) . 'a_accessor__d', __FILE__);
ok(1, 'inteface initialized 1');
Numeric::LL_Array::_create_handler('access', 'Numeric::LL_Array::access_d__', __FILE__, 'd');
ok(1, 'inteface initialized 2');
Numeric::LL_Array::create_handler('Numeric::LL_Array::access_d', __FILE__);
ok(1, 'inteface initialized');

is(Numeric::LL_Array::access_d_($s, 0, 0, ""), 345, '0-dim accessor 1');
is(Numeric::LL_Array::access_d__($s, 0, 0, ""), 345, '0-dim accessor 2');
is(Numeric::LL_Array::access_d($s, 0, 0, ""), 345, '0-dim accessor');
# stride/lim=num_of_items
my $form = pack 'i2', 1, 1;
is(Numeric::LL_Array::access_d($s, 0, 1, $form), 345, '1-dim accessor, s');
$form = [1,1];
is(Numeric::LL_Array::access_d($s, 0, 1, $form), 345, '1-dim accessor/array, s');
$form = pack 'i2', 0, 1;
is(Numeric::LL_Array::access_d($s, 0, 1, $form), 345, '1-dim accessor, stride=0, s');
$form = [0, 1];
is(Numeric::LL_Array::access_d($s, 0, 1, $form), 345, '1-dim accessor, stride=0/array, s');

$form = pack 'i2', 1, 1;
is_deeply([Numeric::LL_Array::access_d($s, 0, 1, $form)], [345], '1-dim accessor');
$form = [1,1];
is_deeply([Numeric::LL_Array::access_d($s, 0, 1, $form)], [345], '1-dim accessor/array');
$form = pack 'i2', 0, 1;
is_deeply([Numeric::LL_Array::access_d($s, 0, 1, $form)], [345], '1-dim accessor, stride=0');
$form = [0, 1];
is_deeply([Numeric::LL_Array::access_d($s, 0, 1, $form)], [345], '1-dim accessor, stride=0/array');

$form = pack 'i2', 0, 3;
is_deeply([Numeric::LL_Array::access_d($s, 0, 1, $form)], [(345)x 3], '1-dim accessor x 3, stride=0');
$form = [0, 3];
is_deeply([Numeric::LL_Array::access_d($s, 0, 1, $form)], [(345)x 3], '1-dim accessor x 3, stride=0/array');

$form = pack 'i2', 1, 3;
is_deeply([Numeric::LL_Array::access_d($s, 0, 1, $form)], [345..347], '1-dim accessor x 3');
$form = [1, 3];
is_deeply([Numeric::LL_Array::access_d($s, 0, 1, $form)], [345..347], '1-dim accessor x 3/array');

$form = pack 'i*', 2, 3;
is_deeply([Numeric::LL_Array::access_d($s, 0, 1, $form)], [345,347,349], '1-dim accessor, stride=2');
$form = [2, 3];
is_deeply([Numeric::LL_Array::access_d($s, 0, 1, $form)], [345,347,349], '1-dim accessor, stride=2/array');

$form = pack 'i*', 2, 3, 1, 2;
is_deeply([Numeric::LL_Array::access_d($s, 0, 2, $form)], [[345,347,349],[346,348,350]], '2-dim accessor, stride=2,1');
$form = [2, 3, 1, 2];
is_deeply([Numeric::LL_Array::access_d($s, 0, 2, $form)], [[345,347,349],[346,348,350]], '2-dim accessor, stride=2,1/array');

is(Numeric::LL_Array::access_d($s, 0, 0, "", 1), 345, '0-dim accessor, wrapped');
# stride/lim=num_of_items
$form = pack 'i2', 1, 1;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, 1), [345], '1-dim accessor, wrapped');
$form = [1,1];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, 1), [345], '1-dim accessor/array, wrapped');
$form = pack 'i2', 0, 1;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, 1), [345], '1-dim accessor, stride=0, wrapped');
$form = [0, 1];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, 1), [345], '1-dim accessor, stride=0/array, wrapped');

$form = pack 'i2', 0, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, 1), [(345)x 3], '1-dim accessor x 3, stride=0, wrapped');
$form = [0, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, 1), [(345)x 3], '1-dim accessor x 3, stride=0/array, wrapped');

$form = pack 'i2', 1, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, 1), [345..347], '1-dim accessor x 3, wrapped');
$form = [1, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, 1), [345..347], '1-dim accessor x 3/array, wrapped');

$form = pack 'i*', 2, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, 1), [345,347,349], '1-dim accessor, stride=2, wrapped');
$form = [2, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, 1), [345,347,349], '1-dim accessor, stride=2/array, wrapped');

$form = pack 'i*', 2, 3, 1, 2;
is_deeply(Numeric::LL_Array::access_d($s, 0, 2, $form, 1), [[345,347,349],[346,348,350]], '2-dim accessor, stride=2,1, wrapped');
$form = [2, 3, 1, 2];
is_deeply(Numeric::LL_Array::access_d($s, 0, 2, $form, 1), [[345,347,349],[346,348,350]], '2-dim accessor, stride=2,1/array, wrapped');


is_deeply(Numeric::LL_Array::access_d($s, 0, 0, "", []), [345], '0-dim accessor, into existing');
# stride/lim=num_of_items
$form = pack 'i2', 1, 1;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, []), [345], '1-dim accessor, into existing');
$form = [1,1];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, []), [345], '1-dim accessor/array, into existing');
$form = pack 'i2', 0, 1;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, []), [345], '1-dim accessor, stride=0, into existing');
$form = [0, 1];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, []), [345], '1-dim accessor, stride=0/array, into existing');

$form = pack 'i2', 0, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, []), [(345)x 3], '1-dim accessor x 3, stride=0, into existing');
$form = [0, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, []), [(345)x 3], '1-dim accessor x 3, stride=0/array, into existing');

$form = pack 'i2', 1, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, []), [345..347], '1-dim accessor x 3, into existing');
$form = [1, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, []), [345..347], '1-dim accessor x 3/array, into existing');

$form = pack 'i*', 2, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, []), [345,347,349], '1-dim accessor, stride=2, into existing');
$form = [2, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, []), [345,347,349], '1-dim accessor, stride=2/array, into existing');

$form = pack 'i*', 2, 3, 1, 2;
is_deeply(Numeric::LL_Array::access_d($s, 0, 2, $form, []), [[345,347,349],[346,348,350]], '2-dim accessor, stride=2,1, into existing');
$form = [2, 3, 1, 2];
is_deeply(Numeric::LL_Array::access_d($s, 0, 2, $form, []), [[345,347,349],[346,348,350]], '2-dim accessor, stride=2,1/array, into existing');

is_deeply(Numeric::LL_Array::access_d($s, 0, 0, "", [3, [4]]), [345], '0-dim accessor, into existing non-empty');
# stride/lim=num_of_items
$form = pack 'i2', 1, 1;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]]), [345], '1-dim accessor, into existing non-empty');
$form = [1,1];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]]), [345], '1-dim accessor/array, into existing non-empty');
$form = pack 'i2', 0, 1;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]]), [345], '1-dim accessor, stride=0, into existing non-empty');
$form = [0, 1];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]]), [345], '1-dim accessor, stride=0/array, into existing non-empty');

$form = pack 'i2', 0, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]]), [(345)x 3], '1-dim accessor x 3, stride=0, into existing non-empty');
$form = [0, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]]), [(345)x 3], '1-dim accessor x 3, stride=0/array, into existing non-empty');

$form = pack 'i2', 1, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]]), [345..347], '1-dim accessor x 3, into existing non-empty');
$form = [1, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]]), [345..347], '1-dim accessor x 3/array, into existing non-empty');

$form = pack 'i*', 2, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]]), [345,347,349], '1-dim accessor, stride=2, into existing non-empty');
$form = [2, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]]), [345,347,349], '1-dim accessor, stride=2/array, into existing non-empty');

$form = pack 'i*', 2, 3, 1, 2;
is_deeply(Numeric::LL_Array::access_d($s, 0, 2, $form, [3, [4]]), [[345,347,349],[346,348,350]], '2-dim accessor, stride=2,1, into existing non-empty');
$form = [2, 3, 1, 2];
is_deeply(Numeric::LL_Array::access_d($s, 0, 2, $form, [3, [4]]), [[345,347,349],[346,348,350]], '2-dim accessor, stride=2,1/array, into existing non-empty');

is_deeply(Numeric::LL_Array::access_d($s, 0, 0, "", [3, [4]], 1), [3, [4], 345], '0-dim accessor, into existing non-empty, keep');
# stride/lim=num_of_items
$form = pack 'i2', 1, 1;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]], 1), [3, [4], 345], '1-dim accessor, into existing non-empty, keep');
$form = [1,1];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]], 1), [3, [4], 345], '1-dim accessor/array, into existing non-empty, keep');
$form = pack 'i2', 0, 1;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]], 1), [3, [4], 345], '1-dim accessor, stride=0, into existing non-empty, keep');
$form = [0, 1];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]], 1), [3, [4], 345], '1-dim accessor, stride=0/array, into existing non-empty, keep');

$form = pack 'i2', 0, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]], 1), [3, [4], (345)x 3], '1-dim accessor x 3, stride=0, into existing non-empty, keep');
$form = [0, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]], 1), [3, [4], (345)x 3], '1-dim accessor x 3, stride=0/array, into existing non-empty, keep');

$form = pack 'i2', 1, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]], 1), [3, [4], 345..347], '1-dim accessor x 3, into existing non-empty, keep');
$form = [1, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]], 1), [3, [4], 345..347], '1-dim accessor x 3/array, into existing non-empty, keep');

$form = pack 'i*', 2, 3;
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]], 1), [3, [4], 345,347,349], '1-dim accessor, stride=2, into existing non-empty, keep');
$form = [2, 3];
is_deeply(Numeric::LL_Array::access_d($s, 0, 1, $form, [3, [4]], 1), [3, [4], 345,347,349], '1-dim accessor, stride=2/array, into existing non-empty, keep');

$form = pack 'i*', 2, 3, 1, 2;
is_deeply(Numeric::LL_Array::access_d($s, 0, 2, $form, [3, [4]], 1), [3, [4], [345,347,349],[346,348,350]], '2-dim accessor, stride=2,1, into existing non-empty, keep');
$form = [2, 3, 1, 2];
is_deeply(Numeric::LL_Array::access_d($s, 0, 2, $form, [3, [4]], 1), [3, [4], [345,347,349],[346,348,350]], '2-dim accessor, stride=2,1/array, into existing non-empty, keep');

is(Numeric::LL_Array::access_d($s, 0, 0), 345, '0-dim accessor, dim=0 only');
is(Numeric::LL_Array::access_d($s, 0), 345, '0-dim accessor, no dim');
is(Numeric::LL_Array::access_d($s), 345, '0-dim accessor, no offset');

$form = [-2, 3, 1, 2];
is_deeply(Numeric::LL_Array::access_d($s, 12, 2, $form, 1), [[357,355,353],[358,356,354]], '2-dim accessor, stride=-2,1/array, wrapped');

sub ok_N($$) { my($N, $msg) = @_; ok(1, "$msg: $_") for 1..$N }

my $form1 = [-2, 4, 1, 3];

for my $t (qw(c C s S i I l L q Q f d D)) {
  my $n = 8;
  ok_N($n, "Skip type = $t, no C support"), next
      if $t =~ /[fdD]/ and not $Numeric::LL_Array::typeSizes{$t};
  my $s1 = eval {pack "$t*", 45..58};		# XXXX Wrong; need `!';
  ok_N($n, "Skip type = $t, no pack support"), next unless $s1;
  Numeric::LL_Array::create_handler("main::access_$t", __FILE__);
  ok(1, "handler created, type=$t");
  no strict 'refs';
  is_deeply(&{"access_$t"}($s1, 12, 2, $form, 1), [[57,55,53],[58,56,54]], "2-dim accessor, stride=-2,1/array, wrapped, type=$t, at end");
  my $r = eval {&{"access_$t"}($s1, 13, 2, $form, 1); 1} || $@;
  like $r, qr/Array not fitting/i, 'limit at large end reached';
  $r = eval {&{"access_$t"}($s1, 3, 2, $form, 1); 1} || $@;
  like $r, qr/Array not fitting/i, 'limit at small end reached';
  is_deeply(&{"access_$t"}($s1, 4, 2, $form, 1), [[49,47,45],[50,48,46]], "2-dim accessor, stride=-2,1/array, wrapped, type=$t, at start");
  
  Numeric::LL_Array::create_handler("main::${t}0_incr", __FILE__);
  ok(1, "incr handler created, type=$t");
  ok(&{"${t}0_incr"}($s1, 6, 2, $form), "incr, stride=-2,1, type=$t");
  is_deeply(&{"access_$t"}($s1, 6, 2, $form1, 1), [[52,50,48,45],[53,51,49,46],[53,52,50,48]], "2-dim accessor after incr, stride=-2,1/array, wrapped, type=$t, at start");  
}

