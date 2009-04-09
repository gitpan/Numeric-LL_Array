#!/usr/bin/perl -w
use strict;
use Config;

open OUT_ASS,  '>', "driver_ass.h" or die;
open OUT_0ARG, '>', "driver_0arg.h" or die;
open OUT_1ARG, '>', "driver_1arg.h" or die;
open OUT_2ARG, '>', "driver_2arg.h" or die;

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
$type{Q} = 'Uquad_t' if $Config{d_longlong};
$type{'q'} = 'Quad_t' if $Config{d_longlong};

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

const unsigned char* const duplicate_types_s = "$dups_s";
const unsigned char* name_by_t  = " " "$types_str";
static const unsigned char size_by_t[] = {  1,  $sizeof, 0 };
const unsigned char * const size_by_t_p = size_by_t;

const char*
name_by_type_ord(void)
{
  return name_by_t;
}

const char*
sizeof_by_type_ord(void)
{
  return size_by_t;
}

EOP

# accessors
for my $t (keys %type) {
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
	   map(["RET_${_}__", $_], qw(0 1 2 m1)),
	   ['abs', 'abs'],
	   map [$_, $_, 1], qw(cos sin tan acos asin atan exp log log10 sqrt ceil floor trunc rint)) {
  my @allowed_types = keys %type;
  @allowed_types = grep !/[fdD]/, @allowed_types if $c->[0] eq '~';
  @allowed_types = grep /[fdD]/, @allowed_types if $c->[2];
  my (%c_suff, %c_pref);
  @c_pref{@allowed_types} = @c_suff{@allowed_types} = ('') x @allowed_types;
  $c_suff{D} = 'l' if $c->[2] or $c->[0] eq 'abs';
  $c->[0] eq 'abs' and $c_pref{$_} = 'f' for qw(f d D);
  $c->[0] eq 'abs' and $c_pref{$_} = 'l' for qw(l L);
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
    print OUT_0ARG <<EOP for keys %type;
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
for my $s (keys %type) {
  for my $t (keys %type) {
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

# other 1-arg calls (with possible source and target types)
for my $c (['!', 'negate'], ['-', 'flip_sign'], ['~', 'bit_complement'],
	   ['abs', 'abs'],
	   (map [$_, $_, 1], qw(ceil floor trunc rint)),
	   ['+=', 'plus_assign'], ['-=', 'minus_assign'],
	   ['*=', 'mult_assign'], ['/=', 'div_assign'],
	   ['%=', 'remainder_assign'], ['pow((targ), ', 'pow_assign'],
	   ['<<=', 'lshift_assign'], ['>>=', 'rshift_assign']) {
  my @allowed_types = keys %type;
  @allowed_types = grep !/[fdD]/, @allowed_types if $c->[0] =~ /~|<<|>>|%/;
  my (%c_suff, %c_pref);
  @c_pref{@allowed_types} = @c_suff{@allowed_types} = ('') x @allowed_types;
  $c_suff{D} = 'l' if $c->[0] eq 'abs' or $c->[2];
  $c->[0] eq 'abs' and $c_pref{$_} = 'f' for qw(f d D);
  $c->[0] eq 'abs' and $c_pref{$_} = 'l' for qw(l L);
  my $eq = ($c->[0] =~ s/=$/= /) ? '' : '=';
  my $trailer = ($c->[0] =~ /\(/) ? ')' : '';
  for my $s (@allowed_types) {
    for my $t (@allowed_types) {
      next if $c->[2] and ($s eq $t or $s !~ /[fdD]/);	# $s==$t: done earlier
      my $ccc = $c->[0];
      $ccc =~ s/pow/powl/ if "$s$t" =~ /D/;
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

my(@commutative, %commutative) = qw(+ * == !=);
@commutative{@commutative} = @commutative;

# 2-arg calls (with possible source and target types)
for my $c (['+', 'plus'], ['-', 'minus'],
	   ['*', 'mult'], ['/', 'div'], ['*', 'sproduct'],
	   ['%', 'remainder'], ['pow', 'pow'],
	   ['<', 'lt'], ['<=', 'le'], ['==', 'eq'], ['!=', 'ne'],
	   ['<<', 'lshift'], ['>>', 'rshift']) {
  my @allowed_types = keys %type;
  @allowed_types = grep !/[fdD]/, @allowed_types if $c->[0] =~ /~|<<|>>|%/;
  for my $s1 (@allowed_types) {
    for my $s2 (@allowed_types) {
      next if $ss{$s1} > $ss{$s2} and $commutative{$c->[0]};
      my %t;  $t{$s1}++; $t{$s2}++;
      if ($c->[0] eq '*') {{	# Wider output for mult/sproduct
	$t{$_}++ for grep $type{$_}, qw(f d D q Q);
	last;			# too slow compile otherwise???
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
      for my $t (keys %t) {
        my ($mid, $pre) = ($c->[0], '');
	($mid, $pre) = (',', $mid) if $mid =~ /pow/;
        $pre =~ s/pow/powl/ if "$s1$s2$t" =~ /D/;
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
	{ 0, (f${list_t}_p)&croak_on_invalid_entry},
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
