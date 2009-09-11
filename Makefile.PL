use ExtUtils::MakeMaker;
use Config;

my %skip_sinl;
my $cc_E_out = `$Config{cc} -E -I. utils/try.h` || 0; # May fail on some systems
if ($cc_E_out =~ / \b double \b .* \b sin \b .* \( .* \b double /x ) {
  # apparently, we can trust $cpp_out
  unless ($cc_E_out =~ / \b long \s+ double \b .* \b sinl \b .* \( .* \b long \s+ double /x ) {
    warn <<EOW;
Looks like you do not have sinl() (is it BSD, and is BSD *that* broken?)...
  I will try to skip defining similar functions...
EOW
    $skip_sinl{WRITE_DRIVER_OPT} = '-no_sinl';
  }
} else {
  warn "cc -E failed; I assume non-BSD, so not a completely broken long double...\n";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Numeric::LL_Array',
    VERSION_FROM      => 'lib/Numeric/LL_Array.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Numeric/LL_Array.pm', # retrieve abstract from module
       AUTHOR         => 'Ilya Zakharevich <ilyaz@cpan.org>') : ()),
    LIBS              => ['-lm'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    macro	      => \%skip_sinl,
    clean	      => { FILES => 'driver_0arg.h driver_1arg.h driver_2arg.h driver_ass.h' },
);

sub MY::postamble {
  ($[ < 5.006 ? "
PERLRUN = $^X

" : '') .
  '
AUTOGEN_C_FILES = driver_ass.h driver_0arg.h driver_1arg.h driver_2arg.h

LL_Array$(OBJ_EXT) : driver_h.h

driver_ass$(OBJ_EXT) :  driver_h.h driver_ass.h  code_accessor.h

driver_0arg$(OBJ_EXT) : driver_h.h driver_0arg.h code_0arg.h

driver_1arg$(OBJ_EXT) : driver_h.h driver_1arg.h code_1arg.h

driver_2arg$(OBJ_EXT) : driver_h.h driver_2arg.h code_2arg.h

$(AUTOGEN_C_FILES): utils/write_driver.pl
	$(PERLRUN) utils/write_driver.pl $(WRITE_DRIVER_OPT)
';
}

