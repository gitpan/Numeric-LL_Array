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

$VERSION = '0.02';

use strict;

require XSLoader;
XSLoader::load('Numeric::LL_Array', $Numeric::LL_Array::VERSION);

# Preloaded methods go here.
%Numeric::LL_Array::duplicateTypes = split //, duplicateTypes();
@Numeric::LL_Array::typeSizes{split //, typeNames()} = map ord, split //, typeSizes();

%Numeric::LL_Array::translateTypes = %Numeric::LL_Array::duplicateTypes;
@Numeric::LL_Array::translateTypes{split //, typeNames()} = split //, typeNames();

$Numeric::LL_Array::typeSizes{$_}
  = $Numeric::LL_Array::typeSizes{$Numeric::LL_Array::duplicateTypes{$_}}
    for keys %Numeric::LL_Array::duplicateTypes;

my %t = qw(access -1 _0arg 0 _1arg 1 _2arg 2);
my %t_r = reverse %t;
sub _create_handler ($$$$;@) {
  my($how, $name, $file, $targ, $flavor, @src) = @_;
  my $t = $t{$how};
  die "Unknown type of handler `$how'" unless defined $t;
  die "Unexpected number of arguments for `$how'"
    unless ($t >= 0 ? $t : 0) == @src;
  die "Flavor unexpected for `$how'" if defined $flavor and -1 == $t;
  my $types = join '', map chr $Numeric::LL_Array::typeSizes{$_}, $targ, @src;
  $_ = ($Numeric::LL_Array::translateTypes{$_} or die "Unknown type: $_")
    for $targ, @src;
  my $src = join '', @src;
  if (-1 == $t) {
    init_interface($name, $t, "${types}a_accessor__$targ", $file);
  } else {
    my $to = $src ? 2 : '';		# Do not start identifier with 2
    init_interface($name, $t, "${types}$src$to$targ${t}_$flavor", $file);
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

Numeric::LL_Array - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Numeric::LL_Array;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Numeric::LL_Array, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Ilya Zakharevich E<lt>ilyaz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Ilya Zakharevich <ilyaz@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
