#!/usr/bin/perl -w

# test POD coverage

use strict;
use Test::More;

BEGIN
   {
   chdir 't' if -d 't';
   use lib '../lib';
   eval "use Test::Pod::Coverage";
   plan skip_all => 'Test::Pod::Coverage not installed on this system' if $@;
   plan tests => 2;
   };

my $trust = { coverage_class => 'Pod::Coverage::CountParents' };

for my $p (qw(
  Dicop::Proxy
  Dicop::Proxy::Config
  ))
  {
  pod_coverage_ok( $p, $trust, "$p is covered");
  }

