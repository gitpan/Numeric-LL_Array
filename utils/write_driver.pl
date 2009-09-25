#!/usr/bin/perl -w
use strict;
use Config;

my $no_sinl = ($ARGV[0] || '') eq '-no_sinl';
my $has_sinl = !$no_sinl || 0;

open OUT_ASS,  '> driver_ass.h'  or die;
open OUT_0ARG, '> driver_0arg.h' or die;
open OUT_1ARG, '> driver_1arg.h' or die;
open OUT_2ARG, '> driver_2arg.h' or die;

print OUT_0ARG "const int has_sinl = $has_sinl;\n\n";

my(@list_ass, @list_0arg, @list_1arg, @list_2arg, $name);

my %type = (		# XXX Add long flavors later...
		c => 'signed char',
		C => 'unsigned char',
		s => 'signed short',
		S => 'unsigned short',
		i => 'signed int',
		I => 'unsigned int',
		l => 'signed long',
		L => 'unsigned long',
		f => 'float',
		d => 'double',
	);

$type{D} = 'long double' if $Config{d_longdbl};
# XXXX Could do also with d_longlong, but need to define Quad_t ourselves...
$type{'q'} = 'Quad_t', $type{Q} = 'Uquad_t' if $Config{d_quad};

# The generated C file takes ages to compile; reduce duplicates...
my %size = (qw(c 1 s), $Config{shortsize}, i => $Config{intsize},
	l => $Config{longsize}, q => $Config{longlongsize},
	d => $Config{doublesize}, D => $Config{longdblsize},
	f => length pack 'f', 0);
my($prevs, $prev, %conv, %dups, %dups_lc) = 0;
my(@first, @dups, %ss, %first_ind);

for my $t (grep $type{$_}, qw(c s i l q)) {
  my $ss = $ss{$t} = $size{$t} || ($prevs+1);  # Some Config stuff undefined???
  push(@dups, $t), $dups{$t} = $conv{$t} = $prev, next if $ss <= $prevs;
  push @first, $t;
  $first_ind{$t} = @first;
  $prev = $conv{$t} = $t;
  $prevs = $ss;
}
$dups{uc $_} = uc $dups{$_} for keys %dups;
$ss{uc $_} = $ss{$_} for keys %ss;
my @first_uc = map uc, @first;

($prevs, $prev) = 0;
for my $t (grep $type{$_}, qw(f d D)) {
  my $ss = $ss{$t} = $size{$t} || ($prevs+1);  # Some Config stuff undefined???
  push(@dups, $t), $conv{$t} = $prev, $dups{$t}++, next if $ss <= $prevs;
  push @first, $t;
  $first_ind{$t} = @first;
  $prev = $conv{$t} = $t;
  $prevs = $ss;
}
# warn "Dups: @dups{keys %dups}";
delete $type{$_} for keys %dups;

#my @dup = sort {} keys %dups;

my $dups_s = join '', map "$_$dups{$_}", keys %dups;
my $sizeof = join ', ', map "sizeof($type{$_})", @first, @first_uc;
my $types_str = join '', @first, @first_uc;

print OUT_0ARG <<EOP;
#define RET_0__(a)	(0)
#define RET_1__(a)	(1)
#define RET_2__(a)	(2)
#define RET_m1__(a)	(-1)

const char duplicate_types_s[] = "$dups_s";
const char name_by_t[]         = " " "$types_str";
const unsigned char size_by_t[]      = {  1,  $sizeof, 0 };

EOP

#sub protect_q ($) {my $t = shift; $t =~ /q/i ? ('#ifdef HAVE_QUAD', "#endif") : ('' '')}
#my($protect_q, $unprotect_q) = ('','');

my @use_types = grep $type{$_}, split //, 'cCsSiIlLfdDqQ';	# A particular order

# accessors
for my $t (@use_types) {
  my $create = ($t =~ /[fdDqQ]/) ? 'newSVnv' 
    : (($t =~ /[CSIL]/) ? 'newSVuv' : 'newSViv');

  $name = "a_accessor__$t";
  push @list_ass, [$name, $t];
  print OUT_ASS <<EOP;
#define TARG_ELT_TYPE		$type{$t}
#define THIS_OP_NAME		$name
#define newSV_how		$create
#include "code_accessor.h"
#undef  newSV_how
#undef  TARG_ELT_TYPE
#undef  THIS_OP_NAME

EOP
}

# do 1-arg calls inplace, and, for floating-point, with source

for my $c (['!', 'negate'], ['-', 'flip_sign'], ['~', 'bit_complement'],
	   map(["RET_${_}__", $_], qw(0 1 2 m1)), ['my_ne0', 'ne0'],
	   ['abs', 'abs', 0],
	   map([$_, $_, 0], qw(log log10 sqrt)),	# Allow int args
	   map([$_, $_, 1], qw(cos sin tan acos asin atan exp ceil floor trunc rint)),) {
  my @allowed_types = @use_types;
  @allowed_types = grep !/[fdD]/, @allowed_types if $c->[0] eq '~';
  @allowed_types = grep /[fdD]/, @allowed_types if $c->[2];
  @allowed_types = grep !/D/, @allowed_types if defined $c->[2] and $no_sinl;
  my (%c_suff, %c_pref);
  @c_pref{@allowed_types} = @c_suff{@allowed_types} = ('') x @allowed_types;
  $c_suff{D} = 'l' if defined $c->[2];
  $c->[0] eq 'abs' and $c_pref{$_} = 'f' for qw(f d D);
  $c->[0] eq 'abs' and $c_pref{$_} = 'l' for qw(l);
  $c->[0] eq 'abs' and $c_pref{$_} = 'my_ll' for qw(q);
  $c->[0] eq 'abs' and $c_pref{$_} = 'my_u' for qw(C S I L Q);
  $name = "${_}0_$c->[1]", push(@list_0arg, [$name, $_]),
    print OUT_0ARG <<EOP for @allowed_types;
#define TARG_ELT_TYPE		$type{$_}
#define DO_0OP(targ)		(targ) = $c_pref{$_}$c->[0]$c_suff{$_}(targ)
#define THIS_OP_NAME		$name
#include "code_0arg.h"
#undef  TARG_ELT_TYPE
#undef  DO_0OP
#undef  THIS_OP_NAME

EOP
  next unless $c->[2];

  $name = "${_}2${_}1_$c->[1]", push(@list_1arg, [$name, $_, $_]),
    print OUT_1ARG <<EOP for @allowed_types;
#define SOURCE_ELT_TYPE		$type{$_}
#define TARG_ELT_TYPE		$type{$_}
#define DO_1OP(targ,source)	(targ) = $c_pref{$_}$c->[0]$c_suff{$_}(source)
#define THIS_OP_NAME		$name
#include "code_1arg.h"
#undef  SOURCE_ELT_TYPE
#undef  TARG_ELT_TYPE
#undef  DO_1OP
#undef  THIS_OP_NAME

EOP
}

# C modifiers (as 0-arg)
for my $c (['++', 'incr'], ['--', 'decr']) {
  $name = "${_}0_$c->[1]", push(@list_0arg, [$name, $_]),
    print OUT_0ARG <<EOP for @use_types;
#define TARG_ELT_TYPE		$type{$_}
#define DO_0OP(targ)		$c->[0](targ)
#define THIS_OP_NAME		$name
#include "code_0arg.h"
#undef  TARG_ELT_TYPE
#undef  DO_0OP
#undef  THIS_OP_NAME

EOP
}

# conversion calls (1-arg)
for my $s (@use_types) {
  for my $t (@use_types) {
    my $mid_convert = '';
    $mid_convert = '(int)' if "$s$t" =~ /[cs][fdD]|[fdD][cs]/; # Needed?
    $mid_convert = '(unsigned int)' if "$s$t" =~ /[CS][fdD]|[fdD][CS]/; # Needed?
    $name = "${s}2${t}1_assign", push(@list_1arg, [$name, $t, $s]),
      print OUT_1ARG <<EOP;
#define SOURCE_ELT_TYPE		$type{$s}
#define TARG_ELT_TYPE		$type{$t}
#define DO_1OP(targ,source)	(targ) = (TARG_ELT_TYPE)$mid_convert(source)
#define THIS_OP_NAME		$name
#include "code_1arg.h"
#undef  SOURCE_ELT_TYPE
#undef  TARG_ELT_TYPE
#undef  DO_1OP
#undef  THIS_OP_NAME

EOP
  }
}

my %fp_vars = qw( << ldexp >> ldexp_neg );

# other 1-arg calls (with possible source and target types)
for my $c (['!', 'negate'], ['-', 'flip_sign'], ['~', 'bit_complement'],
	   ['my_ne0', 'ne0'],
	   (map [$_, $_, 1], qw(ceil floor trunc rint)),
	   map([$_, $_, 0], qw(log log10 sqrt abs)),	# Allow int args
	   ['+=', 'plus_assign'], ['-=', 'minus_assign'],
	   ['*=', 'mult_assign'], ['/=', 'div_assign'],
	   ['|=', 'bitor_assign'], ['&=', 'bitand_assign'], ['^=', 'bitxor_assign'],
	   ['%=', 'remainder_assign'], ['pow((targ), ', 'pow_assign'],
	   ['<<=', 'lshift_assign'], ['>>=', 'rshift_assign']) {
  my @allowed_types = @use_types;
  @allowed_types = grep !/[fdD]/, @allowed_types if $c->[0] =~ /[~%|&^]/;
  @allowed_types = grep !/D/, @allowed_types
    if $no_sinl and ($c->[0] =~ /^pow/ or defined $c->[2]);
  my (%c_suff, %c_pref);
  @c_pref{@allowed_types} = @c_suff{@allowed_types} = ('') x @allowed_types;
  $c_suff{D} = 'l' if defined $c->[2];
  $c->[0] eq 'abs' and $c_pref{$_} = 'f' for qw(f d D);
  $c->[0] eq 'abs' and $c_pref{$_} = 'l' for qw(l);
  $c->[0] eq 'abs' and $c_pref{$_} = 'my_ll' for qw(q);
  $c->[0] eq 'abs' and $c_pref{$_} = 'my_u' for qw(C S I L Q);
  for my $s (@allowed_types) {
    next if $s =~ /[fdD]/ and $c->[0] =~ /<<|>>/;
    for my $t (@allowed_types) {
      next if $c->[2] and ($s eq $t or $s !~ /[fdD]/);	# $s==$t: done earlier
      (my $_c = my $ccc = $c->[0]) =~ s/=//;
      $ccc = "$fp_vars{$_c}((targ), " if $fp_vars{$_c} and "$s$t" =~ /[fdD]/;
      $ccc =~ s/^(pow|ldexp(_neg)?)/${1}l/ if "$s$t" =~ /D/;
      my $eq = ($ccc =~ s/=$/= /) ? '' : '=';
      my $trailer = ($ccc =~ /\(/) ? ')' : '';
      $name = "${s}2${t}1_$c->[1]", push(@list_1arg, [$name, $t, $s]),
	print OUT_1ARG <<EOP;
#define SOURCE_ELT_TYPE		$type{$s}
#define TARG_ELT_TYPE		$type{$t}
#define DO_1OP(targ,source)	(targ) $eq $c_pref{$s}$ccc$c_suff{$s}(source)$trailer
#define THIS_OP_NAME		$name
#include "code_1arg.h"
#undef  SOURCE_ELT_TYPE
#undef  TARG_ELT_TYPE
#undef  DO_1OP
#undef  THIS_OP_NAME

EOP
    }
  }
}

my(@commutative, %commutative) = qw(+ * == != my_eq my_ne);
@commutative{@commutative} = @commutative;

# 2-arg calls (with possible source and target types)
for my $c (['+', 'plus'], ['-', 'minus'],
	   ['*', 'mult'], ['/', 'div'], ['*', 'sproduct'],
	   ['|', 'bitor'], ['&', 'bitand'], ['^', 'bitxor'],
	   ['%', 'remainder'], ['pow', 'pow'],
	   (map ["my_$_", $_], qw( lt le eq ne )),
	   # ['<', 'lt'], ['<=', 'le'], ['==', 'eq'], ['!=', 'ne'],
	   ['<<', 'lshift'], ['>>', 'rshift']) {
  my @allowed_types = @use_types;
  @allowed_types = grep !/[fdD]/, @allowed_types if $c->[0] =~ /[~%|&^]/;
  @allowed_types = grep !/D/, @allowed_types if $no_sinl and $c->[0] eq 'pow';
  for my $s1 (@allowed_types) {
    for my $s2 (@allowed_types) {
      next if ($ss{$s1} > $ss{$s2}
	       or $ss{$s1} == $ss{$s2} and "$s1$s2" =~ /[CSILQ][csilq]/)
	and $commutative{$c->[0]};
      next if $s2 =~ /[fdD]/ and $c->[0] =~ /<<|>>/;
      my %t;  $t{$s1}++; $t{$s2}++;
      if ($c->[0] eq '*') {{	# Wider output for mult/sproduct
	$t{$_}++ for grep $type{$_}, qw(f d D q Q);
	last;			# compile too slow otherwise???
	if ("$s1$s2" =~ /cs/) {
	  $t{$_}++ for qw(l L i I);
	}
	if ("$s1$s2" =~ /CS/) {
	  $t{$_}++ for qw(L I);
	}
	if ("$s1$s2" =~ /i/) {
	  $t{$_}++ for qw(l L I);
	}
	if ("$s1$s2" =~ /I/) {
	  $t{$_}++ for qw(l L);
	}
      }}
      if ($c->[0] =~ /^my_/) {	# Any-signed-int output for comparisons
	$t{$_}++ for grep $type{$_}, qw(c s i l q);
        delete $t{$_} for qw(C S I L Q);
      }				# Increases the DLL size 1.5 times???
      for my $t (keys %t) {
        my ($mid, $pre) = ($c->[0], '');
	($mid, $pre) = (',', $mid) if $mid =~ /^\w+$/;
	($mid, $pre) = (',', $fp_vars{$mid})
	  if $fp_vars{$mid} and "$s1$t" =~ /[fdD]/;
        $pre =~ s/^(pow|ldexp(_neg)?)/${1}l/   if "$s1$s2$t" =~ /D/;
	$pre =~ s/^(my_\w\w)$/$1_su/ if "$s1$s2" =~ /^[csilq][CSILQ]$/;
	$pre =~ s/^(my_\w\w)$/$1_us/ if "$s1$s2" =~ /^[CSILQ][csilq]$/;
	my $preassign = ($c->[1] eq 'sproduct') ? '+' : '';
	$name = "${s1}${s2}2${t}2_$c->[1]", push(@list_2arg, [$name, $t, $s1, $s2]),
	  print OUT_2ARG <<EOP;
#define SOURCE1_ELT_TYPE	$type{$s1}
#define SOURCE2_ELT_TYPE	$type{$s2}
#define TARG_ELT_TYPE		$type{$t}
#define DO_2OP(targ,s1,s2)	(targ) $preassign= $pre((s1) $mid (s2))
#define THIS_OP_NAME		${s1}${s2}2${t}2_$c->[1]
#include "code_2arg.h"
#undef  SOURCE1_ELT_TYPE
#undef  SOURCE2_ELT_TYPE
#undef  TARG_ELT_TYPE
#undef  DO_2OP
#undef  THIS_OP_NAME

EOP
      }
    }
  }
}

my %list_t = (_ass  => [\@list_ass,  0, \*OUT_ASS],
	      _0arg => [\@list_0arg, 0, \*OUT_0ARG],
	      _1arg => [\@list_1arg, 1, \*OUT_1ARG],
	      _2arg => [\@list_2arg, 2, \*OUT_2ARG]);
for my $list_t (qw(_ass _0arg _1arg _2arg)) {
  print {$list_t{$list_t}[2]} <<EOP;
const f${list_t}_descr f${list_t}_names[] = {
	{ "\\0\\0\\0\\0", (f${list_t}_p)&croak_on_invalid_entry},
EOP

  for my $f (@{ $list_t{$list_t}[0] }) {
    my($name) = @$f;
    die "array `@$f' of unexpected length" unless @$f == $list_t{$list_t}[1]+2;
    my @args = @$f[1..$#$f];
    $_ = sprintf qq("\\%03o"), $ss{$_} for @args;
    print {$list_t{$list_t}[2]} <<EOP;
    { @args "$name", &$name },
EOP
  }

  print {$list_t{$list_t}[2]} <<EOP;
};

const f${list_t}_descr * const f${list_t}_names_p = f${list_t}_names;
const int f${list_t}_names_c = sizeof(f${list_t}_names)/sizeof(f${list_t}_names[0]);

EOP
}

close OUT_ASS or die;
close OUT_0ARG or die;
close OUT_1ARG or die;
close OUT_2ARG or die;
