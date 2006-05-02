#!/usr/bin/perl -w

# chekc Dicop::Server::Config

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 5;

  use_ok (qw/Dicop::Proxy::Config/);
  use_ok (qw/Dicop::Config/);
  }

can_ok ('Dicop::Proxy::Config', qw/
  allowed_keys
  /);

# check that our sample config file is valid
  
my $cfg = Dicop::Config->new( '../config/proxy.cfg.sample' );

my $allowed = Dicop::Proxy::Config->allowed_keys();

is (ref($allowed), 'HASH', 'allowed ok');

my $msg = $cfg->check($allowed);

is ($msg, undef, 'no error');

1;
