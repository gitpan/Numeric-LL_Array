use 5.008007;
use ExtUtils::MakeMaker;
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
);

sub MY::postamble {
  '
AUTOGEN_C_FILES = driver_ass.h driver_0arg.h driver_1arg.h driver_2arg.h

LL_Array$(OBJ_EXT) : driver_h.h

driver_ass$(OBJ_EXT) :  driver_h.h driver_ass.h  code_accessor.h

driver_0arg$(OBJ_EXT) : driver_h.h driver_0arg.h code_0arg.h

driver_1arg$(OBJ_EXT) : driver_h.h driver_1arg.h code_1arg.h

driver_2arg$(OBJ_EXT) : driver_h.h driver_2arg.h code_2arg.h

$(AUTOGEN_C_FILES): write_driver.pl
	$(PERLRUN) write_driver.pl
';
}

