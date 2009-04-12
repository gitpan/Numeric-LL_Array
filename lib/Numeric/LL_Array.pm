package Numeric::LL_Array;

require Exporter;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Numeric::LL_Array ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = '0.03';

my %exported;
sub import {
  my($p, $f, $renew) = ( shift, (caller)[1] );
  create_handler(__PACKAGE__ . "::$_", $f),
    for grep !defined &{__PACKAGE__ . "::$_"}, @_;
  defined &{__PACKAGE__ . "::$_"}
    and ( $exported{$_}++ or ++$renew, push @EXPORT_OK, $_ ) for @_;
  # change to %EXPORT_OK ignored unless Exporter cache is invalidated
  undef %EXPORT if $renew;
  # warn "EXPORT_OK: @EXPORT_OK\n";
  Exporter::export($p,(caller(0))[0],@_);
}

use strict;

eval {
  require XSLoader;
  XSLoader::load('Numeric::LL_Array', $Numeric::LL_Array::VERSION);
   1;
} or do {
   require DynaLoader;
   push @Numeric::LL_Array::ISA, 'DynaLoader';
   bootstrap Numeric::LL_Array $Numeric::LL_Array::VERSION;
};

# Preloaded methods go here.
%Numeric::LL_Array::duplicateTypes = split //, duplicateTypes();
@Numeric::LL_Array::typeSizes{split //, typeNames()} = map ord, split //, typeSizes();

%Numeric::LL_Array::translateTypes = %Numeric::LL_Array::duplicateTypes;
@Numeric::LL_Array::translateTypes{split //, typeNames()} = split //, typeNames();

$Numeric::LL_Array::typeSizes{$_}
  = $Numeric::LL_Array::typeSizes{$Numeric::LL_Array::duplicateTypes{$_}}
    for keys %Numeric::LL_Array::duplicateTypes;
my %sizePack;
eval { $sizePack{length pack $_, 0} ||= $_ } for qw(c s! s i l! l q);
my(%packId, $t);
$t = $sizePack{$Numeric::LL_Array::typeSizes{$_} || 'nonesuch'}
  and $packId{$_} = $t and $packId{uc $_} = uc $t for qw(c s i l q);

$packId{format} = $t if $t = $sizePack{ptrdiff_t_size()};
$packId{$_} = $_ for grep defined $Numeric::LL_Array::typeSizes{$_}, qw(f d D);

sub packId      ($) { my($t,$r) = shift; $r = $packId{$t} and return $r;
		      die "Type `$t' not handable via Perl pack()"}
sub packId_star ($) { packId(shift) . '*' }

eval <<EOE for keys %packId;
  sub packId_$_      () { "$packId{$_}"  }
  sub packId_star_$_ () { "$packId{$_}*" }
EOE

my(@commutative, %invert) = qw(plus mult eq ne);
@invert{@commutative} = @commutative;
my %i = qw(gt lt ge le);
@invert{keys %i} = values %i;

my %t = qw(access -1 _0arg 0 _1arg 1 _2arg 2);
my %t_r = reverse %t;
sub _create_handler ($$$$;@) {
  my($how, $name, $file, $targ, $flavor, @src) = @_;
  my $tt = my $t = $t{$how};
  die "Unknown type of handler `$how'" unless defined $t;
  die "Unexpected number of arguments for `$how'"
    unless ($t >= 0 ? $t : 0) == @src;
  die "Flavor unexpected for `$how'" if defined $flavor and -1 == $t;
  $_ = ($Numeric::LL_Array::translateTypes{$_} or die "Unknown type: $_")
    for $targ, @src;
  if ($invert{$flavor || 0}
      and ($invert{$flavor} ne $flavor or
	   $Numeric::LL_Array::typeSizes{$src[0]} > $Numeric::LL_Array::typeSizes{$src[1]})) {
    # Only one of the equivalent flavors is present as a C function
    @src = @src[1,0];
    $flavor = $invert{$flavor};
    $tt = -$t;
  }
  my $types = join '', map chr $Numeric::LL_Array::typeSizes{$_}, $targ, @src;
  my $src = join '', @src;
  if (-1 == $t) {
    init_interface($name, $t, "${types}a_accessor__$targ", $file);
  } else {
    my $to = $src ? 2 : '';		# Do not start identifier with 2
    init_interface($name, $tt, "${types}$src$to$targ${t}_$flavor", $file);
  }
}

sub create_handler ($$) {
  my($name, $file, $flavor, $targ, @src, $how) = (shift, shift);
  (my $n = $name) =~ s/^.*:://s;
  if ($n =~ /^access_(.)$/) {
    $how = 'access';
    $targ = $1;
  } elsif ($n =~ /^(.{0,2})(?:^|2)(.)(.)_(.*)$/ and $3 eq length $1) {
    $how = $t_r{$3};
    $flavor = $4;
    $targ = $2;
    @src = split //, "$1";	# Convert to string before REx...
  } else {
    die "Unrecognized name `$name' of a handler"
  }
  _create_handler($how, $name, $file, $targ, $flavor, @src);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Numeric::LL_Array - Perl extension for low level operations over numeric arrays.

=head1 SYNOPSIS

  use Numeric::LL_Array;
  blah blah blah

=head1 DESCRIPTION

One of the principal overheads of using Perl for numeric vector calculations
is the need to constantly create and destroy a large amount of Perl values
(there is no such overhead in calculations over scalars, since Perl knows how
to reuse implicit temporary variables).

Thus, in this package, we provide a way to manipulate vectors "in
place" without creation of new Perl values.  Additionally, the
calculations over slots in a vector are performed in C, thus
significantly reducing overhead of Perl over C (which, for I<literal>
translation from C to Perl, is of order 80..200 times).

One of the design goals is that many vectors should be able to use the
same C array (e.g., of type double[]) - possibly with offset and a
stride, so performing an operation over a I<subarray> does not require
a new allocation.  The C array is stored in PVX of a Perl variable, so
it may be (eventually) refcounted in the usual Perlish way.

=head2 Playgrounds and layout of strides

A I<playground> is just (a region in) a Perl string, with the buffer
propertly alighed to keep a massive of a certain C type.  This way, one gets,
e.g., C<unsigned char>-playground, or C<long double>-playground, etc.; we
call this C type the I<flavor> of the playground.  One describes a certain
position in the playground in units of the size of the corresponding C type;
e.g., position 3 in C<double> array would typically be at offset of 24 bytes
from the start of playground.

A multi-dimensional array of size C<SIZE1 x SIZE2 x ... x SIZEn> may be
placed into a playground in many different ways; we allow modification of
the I<start position> (the position of the element with index (0,0,...,0)),
and of I<strides>.  There is one stride per dimension of array; the stride
describes how the position of the element changes when one increments the
index by 1 in the particular coordinate in the array.

For example, the array C<0..4> with start 3 and stride 2 occupies the
following positions in the playground:

 content   * * * 0 * 1 * 2 * 3 * 4 ...
 position  0 1 2 3 4 5 6 7 8 9 .......

Note that when plotting this picture one does not care about the flavor of
the playground.

Likewise, the 2-dimensional array with contents

  11 12 13 14
  21 22 23 24

and start 1, horizontal stride 2, and vertical stride 3 takes these positions;

  * 11 * 12 21 13 22 14 23 * 24 ....

and with start 12, horizontal stride -1, and vertical stride -5 takes

  *  *  *  * 24 23 22 21  * 14 13 12 11 ...
  0  1  2  3  4  5  6  7  8  9 10 11 12 ...

The major advantage of this flexibility is that one can work with subarrays
of the given array, with the transposed array, and with the reflected array
without reshuffling I<the content of the array>, but with only changes
in the start position and in the strides.  For example, to access the
transposed 2-dimensional array, one just accesses the same data with 2 strides
interchanged.  Likewise, by decreasing I<dimension>, one can assess columns
and row of the matrix without moving the contents.

Other examples: one can fit C<N x M x K> 0-array into playground of size 1
using strides 0,0,0.  And one can fit C<N x N> identity matrix into a
playground of size C<2N-1> by using strides 1,-1.

=head2 Encoding format of an array

To completely specify an array to the API of this module one needs to
provide the C type, the playground of the array, the start offset, its
I<dimension> (e.g., 1 for vectors, 2 for matrices etc), and its
I<format>, which is the list of the sizes of the array in each
particular direction, and the corresponding strides, in the order
C<STRIDE1 COUNT1 STRIDE2 COUNT2 ...>.  To avoid confusion, it makes
sense to use the name I<arity> for the number I<dimension>, and use
word I<dimensions> for the list C<COUNT1 COUNT2 ... COUNTn> (here C<n> is
the "arity").

The format may be encoded as a list reference, or as a packed list of
C values of type C<ptrdiff_t>.  It is I<not> required that the list contains
exaclty C<2*dimension> elements; it may contain more, and the rest is
ignored.  This way, one can access rows of matrices without copying the
content of the matrix, I<and> without touching the format of the matrix -
only by decreasing dimension and modifying the starting position.

Note that the flavor of the array is not a part of the format.  For
this low-level API, each function is designed to work only with a
certain flavor an array (e.g., if operating on 3 arrays, it assumes 3
particular flavors, one for each of 3 arguments); so given a
particular function, the required flavor of the argument is fully
described by its position in the argument list.  (There is no
error-checking in this regard, it is the caller's responsibility to
follow flavors correctly.)  So the flavors are, essentially, encoded
in the name of the function.

For example, a function for high-level semantic C<add_assign($target,
$source)> (implementing operation C<$target += $source>), can take
arguments

  source_playground, target_playground, dim, start_source, start_target,
       format_source, format_target

E.g., for $target of type C<double>, and source of type C<unsigned
short>, the name of the function may encode letters C<"d"> and C<"S">
(in analogy to Perl C<pack> formats).  (The actual name used is
C<S2d1_add_assign>, see L<"Naming conventions for handlers">.)

The semantic of this module is that it is the I<target> dimensions
which are assumed to be used; so from the source format only the
strides is used, and the C<COUNTn> positions are ignored.  Likewise,
the arity dim is assumed to be common for arrays, and both formats
should contain at least C<2*dimension> elements.

=head2 The accessors

Accessor handlers take the following arguments (with defaults indicated):

 @a = access_T($p, $offset = 0, $dim = 0, $format = undef,
	       $in = undef, $keep = FALSE);

extracts a slice of playground $p into Perlish data structure (using
references to arrays of references etc. as deep as specified by $dim).

The playground $p, and offset/dim/format arguments have the same sense
as for other handlers.  If $in is not defined, the "external" layer of
the extracted data is put into elements of array @a (so if $dim is 1,
elements of @a are numbers; if it is 2, elements are references to
arrays of numbers, etc); if $in is TRUE, the returned value is a
scalar containing an array reference (so if dim is 1, $a[0] contains a
reference to an array of numbers, etc).

If $in is an array reference, then instead of putting the "external"
layer of Perlish array into @a, it is put into the referenced array.
The fortune of existing elements of the referenced array is governed
by $keep; if FALSE, the existing content is removed; if TRUE; the
returned data is appended after the end of existing data.


=head2 Naming conventions for handlers

There are 4 types of handlers: I<accessors>, and I<modifying handlers>
(with 0,1,2 sources).  For modifying handlers, the argument which is
write-only or read-write is called C<target>, and the read-only
arguments are I<sources>.

Perl functions for conversion from C<Numeric::LL_Array> arrays to
Perl arrays are called C<access_T>; here C<T> is the letter of pack() specifier
corresponding to I<native> C type (e.g., to access native C C<signed long> one
uses pack() specifier C<"l!">; since C<!> means I<native>, we drop it,
and use C<access_l>).

Perl functions which modify one array and take no source are named
<T0_type>; here C<T> is a letter encoding the flavor, and C<type> is
the identifier describing the semantic of the function:

  list???

For example, to increment C<signed char> array, one uses the function named
C<c0_incr>.

Perl functions which use one array ("source") to modify another ("target")
are named <S2T1_type>; here C<T> is a letter encoding the target flavor, and
C<S> encodes the source flavor.  C<type> is the identifier describing the
semantic of the function:

  list???

For example, to convert C<unsigned long> array to a C<long double> array,
one uses the function named C<L2D1_assign>.

Likewise, Perl functions which use two arrays ("source1" and "source2") to
modify another ("target") are named <sS2T2_type>; here C<T> is a letter
encoding the target flavor, C<s> and C<S> encode the source1 and source2
flavors correspondingly.  C<type> is the identifier describing the
semantic of the function:

  list???

For example, to add C<signed short> array and C<unsigned int>
and write the result to a C<unsigned long> array, one uses the function named
C<sI2L2_add>.

Note that the number before underscore is the number of "source" arrays,
and the flavors of source arrays preceed the number C<2> in the name.

=head2 EXPORT

None by default.

All handlers are exportable.  So are constants for Perl pack() "type
letter" for each flavor of the array:

  packId_format    packId_star_format
  packId_T         packId_star_T

here C<T> is a flavor specifier for a type used by this module.  The
functions on the left return the letter, on the right return a letter
followed by C<*>.  For example, packId_L() would return C<L!> on newer
Perls, and a suitable substitute on the older ones.

Additionally, functions C<packId($t)>, C<packId_star($t)> are
available; they take type letter (or C<'format'>) as a parameter.

=head2 Build methodology

C functions implementing the handlers of this module are collected into
four I<dictionaries>: for accessors, and for 0-, 1- and 2-sources
modifiers.  Each dictionary is compiled from the C code in one minuscule
C file, F<code_*.h>; this file is loaded multiple times, once per handler,
with a handful of macros describing the operation to perform on each
array element, and C types of array elements.

Each dictionary corresponds to one I<constant wrapper> C file, F<driver_*.c>;
this wrapper contains no C code, only a few preprocessor directives to
include the necessary headers, and the I<autogenerated loader>, F<driver_*.h>.
The loaders are generated by a small Perl script, F<write_driver.pl>;
for each handler, a loader defines necessary macros, and includes the
corresponding file F<code_*.h>.

The memory overhead, and the initial slowdown to define thousands of
XSUBs wrapping the C handlers would be quite measurable.  To avoid
this, at start no handler XSUBs are defined.  What I<is> defined is
four I<XSUB interfaces>; they are "closure XSUBs" (or "interfaces"): to
make them into a real, callable, XSUB, one needs to attach to the interface
the corresponding dictionary entry.  So one extra XSUB is defined which does
such an attachment.

So one can define a handler XSUB for by either calling a convenient
Perl routine create_handler() (which wrapps low-level attacher XSUB),
or by just import()ing the handler (the import()er would call
create_handler() as needed) as in

  use Numeric::LL_Array qw( access_i  c2S1_assign );

So the build architecture consists of:

  an import()er which creates handler XSUBs on the fly;

  an attacher which converts interface-XSUBs into handler XSUBs;

  interface-XSUBs which call entries in the dictionary;

  dictionaries created by F<write_driver.pl> from code in F<code_*.h>.

So the total complexity of this module is about 200 lines of C code,
450 lines of Perl, and 400 lines of XSUB (including some code for testing
and developing).

=head1 BUGS

NEED: product with wider target; same for lshift...
	(need src casts...)
NEED: modf, ldexp, frexp (all take *l), cbrt...
NEED: min/max ???  min_assign???
NEED: How to find first elt which breaks conditions (as in a[n+1] == a[n]+1???
NEED: more intelligent choice of accessors for q/Q and D...
NEED: accessor to long double max-aligned (to 16 when size is between 8 and 16)
NEED: abs() for long long?
NEED: signed vs unsigned comparison? char-vs-quad comparison? cmp?
NEED: pseudo-flavor: k-th coordinate of the index

=head1 AUTHOR

Ilya Zakharevich E<lt>ilyaz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Ilya Zakharevich <ilyaz@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 Possible future

What is needed is hide-the-flavors higher-level wrapper which
automatically chooses handlers basing on flavors of arguments.  Yet
another hiding level would create an overloaded-operation 

Possible layout of an object:
   RV:		playground
   IV:		flavor, dim
   PV:		format
