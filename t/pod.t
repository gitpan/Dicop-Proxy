#!/usr/bin/perl -w

# test POD for correctness

use strict;
use Test::More;

BEGIN
   {
   chdir 't' if -d 't';
   use lib '../lib';
   eval "use Test::Pod";
   # SKIP all and exit if Test::Pod unusable
   plan skip_all => 'Test::Pod not installed on this system' if $@;
   plan tests => 8;
   };

for my $file (qw(
  Dicop/Proxy.pm
  Dicop/Proxy/Config.pm
  ../BUGS
  ../CHANGES
  ../CHANGES-3.00
  ../INSTALL
  ../README
  ../TODO
  ))
  {
  pod_file_ok('../lib/' . $file);
  }
