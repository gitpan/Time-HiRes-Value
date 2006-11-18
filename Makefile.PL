use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Time::HiRes::Value',
   VERSION_FROM => 'lib/Time/HiRes/Value.pm',
   PREREQ_PM => {
      'Time::HiRes' => '0',
   },
);
