#!/usr/bin/perl -w

use Test::More;
use strict;

BEGIN
  {
  unshift @INC, '../lib';
  chdir 't' if -d 't';
  plan tests => 28;
  }

use Dicop::Proxy;

require "common.pl";

Dicop::Event::handler( sub { @_; } );	# zap error handler to be silent

$Dicop::Handler::NO_STDERR = 1;		# no informative messages

can_ok ('Dicop::Proxy', qw/
  _init new type clear_cache
  build_server_talk
  talk_to_server 
  check_auth_request
  cache_request
  remap_request_id
  _client_from_info
  _connect_server
  output

  request_test
  request_work
  report
  /);

###############################################################################
# construct a Data Proxy object using testdata and testconfig

my @data; read_lines();

my $proxy = Dicop::Proxy->new(
  cfg_dir => './test-config', cfg => 'serverp.cfg', _warn => 'not' );
is ($proxy->check(),undef);	# construct was okay

is ($proxy->type(),'proxy');
is (ref($proxy),'Dicop::Proxy');
is (ref($proxy->{_send_cache}),'HASH');
is (ref($proxy->{_info_cache}),'HASH');
is (ref($proxy->{_test_cache}),'Dicop::Cache');
is ($proxy->{_send_id},'req0001');

$proxy->{_send_cache} = { foo => 1 };
$proxy->{_info_cache} = { 8 => 'bah' };
$proxy->{_send_id} = 'req0003';
$proxy->{_req_remap} = { req0003 => 'req0002' };

$proxy->clear_cache();

is (ref($proxy->{_send_cache}),'HASH');
is (scalar keys %{$proxy->{_send_cache}},0);
is (scalar keys %{$proxy->{_info_cache}},0);
is (scalar keys %{$proxy->{_req_remap}},0);
is ($proxy->{_send_id}, 'req0001');

###############################################################################
# build_server_talk() and request remapping

$proxy->clear_cache();
my $request = Dicop::Request->new( id => 'req0001',
 data => 'cmd_request;type_test');
my $info = Dicop::Request->new( id => 'req0003',
 data => 'arch_linux;cmd_auth;version_2.12;id_4');
$proxy->{peeraddress} = '1.2.3.4';
$proxy->cache_request($request,undef,$info);

# send_id is req0003 due to entering one normal request (req0001) and one
# info request (req0002)

# we now have two requests and one info request in our caches:
# req0002 => client's first req
# req0003 => info request for req0002

my $id = 'req0002';
is ($proxy->remap_request_id($id), 'req0001', 'remapping works');

my $txt = $proxy->build_server_talk()."\n";

$txt =~ s/pid_\d+/pid_1234/;		# remove, because it changes
my $cmp = lines(1);			# the text we expect
$cmp =~ s/##BUILD##/$Dicop::Proxy::BUILD/;	# replace because this changes
$cmp =~ s/##VERSION##/$Dicop::Proxy::VERSION/;	# replace because this changes
$txt =~ s/cpuinfo_[^;]+;/cpuinfo_foo;/;		# replace because this changes

is ($txt,$cmp);

is (keys %{$proxy->{_info_cache}}, 1, 'one info request');
is (keys %{$proxy->{_send_cache}}, 1, 'one send request');

###############################################################################
# cache another one

$request = Dicop::Request->new( id => 'req0007',
 data => 'cmd_request;type_test');
$proxy->cache_request($request,undef,$info);

# we now have two requests and one info request in our caches:
# req0002 => client's first req (req0001)
# req0003 => info request for req0002 and req0004
# req0004 => client's second req (req0007)

$id = 'req0004';
is ($proxy->remap_request_id($id), 'req0007', 'remapping works');

#use Data::Dumper; print Dumper($proxy->{_send_cache});

is (keys %{$proxy->{_info_cache}}, 1, 'one info request');
is (keys %{$proxy->{_send_cache}}, 2, 'two send requests');

$info = $proxy->{_info_cache}->{req0003};
is ($info->{for}, 'req0002,req0004', 'info is for req0002 and req0004');

###############################################################################
# parse client requests

#$proxy->parse_client_requests();		# list is empty
#is ($proxy->{_client}, undef);

###############################################################################
# request_work() and request_test()

my $res = $proxy->request_test( $request, undef, $info);
is ($$res, '', 'ref to empty string');

$request = Dicop::Request->new( id => 'req0001',
 data => 'cmd_request;type_work');
$res = $proxy->request_work( $request, undef, $info);
is ($$res, '', 'ref to empty string');

$request = Dicop::Request->new( id => 'req0001',
 data => 'cmd_report;job_test-1;chunk_2;token_2;result_30;status_SUCCESS;crc_cafebabe;took_123');
is ($request->error(),'','no error');
$res = $proxy->report( $request, undef, $info);
is ($$res, '', 'ref to empty string');

###############################################################################
# generate status pages

foreach my $type (qw/main config/)
  {
  my $res = $proxy->handle_requests( "1.2.3.4", "req0001=cmd_status;type_$type" );
  like ($$res, qr/<html>/i, 'looks like HTML to me');
  }

foreach my $type (qw/config/)
  {
  my $res = $proxy->handle_requests( "1.2.3.6", "req0001=cmd_status;type_$type" );
  like ($res, qr/Failed to authenticate/i, 'barfed');
  }

# EOF

1;

END
  {
  # clean in case of error
  unlink 'dicop_request_lock' if -e 'dicop_request_lock';
  }  

###############################################################################
# subs

sub lines
  {
  my $cnt = shift;

  my $t = "";
  while ($cnt > 0)
    {
    $t .= shift @data; $cnt--;
    }
  return $t;
  }

sub read_lines
  {
  # read responses from data section
  while (<DATA>)
    {
    push @data, $_; 
    }
  }

__END__
req0001=arch_linux;cmd_auth;cpuinfo_foo;id_11122333;pid_1234;version_##VERSION##-##BUILD##&req0002=cmd_request;type_test&req0003=arch_linux;cmd_info;for_req0002;id_4;ip_1.2.3.4;version_2.12
