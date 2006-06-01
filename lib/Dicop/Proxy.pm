#############################################################################
# Dicop::Proxy - a proxy for Dicop-Server
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Proxy;
use vars qw($VERSION $BUILD);
$VERSION = '3.03';	# Current version of this package
$BUILD = 0;		# Current build of this package
require  5.008003;	# requires this Perl version or later

use base qw/Dicop::Handler/;

use strict;
use Dicop::Cache;
use Dicop::Event qw/give_up/;
use Dicop::Proxy::Config;
use Dicop::Base;

use Dicop::Connect qw/_connect_server _load_connector/;

# fields used by the proxy part:
#  _info_cache	: contains for each client that connected since the last
#		  time we talked to the server an info-request, sorted by id
#  _send_cache	: contains all requests (minus info requests) that need to be
#		  send to the server
#  _send_id	: last request ID in send cache
#  _req_remap	: maps incoming client request numbers to the ones we sent to
#		  the server to remap server answers back to the client

#############################################################################
# Data flow is:

# For each connect, pre_connect() is called once before handle_requests(). The
# latter will call parse_requests() to create a list of requests. For each
# request, one of:

# request_file
# request_work
# request_test 
# status_main | status_help | status_config | status_style

# will be called. These will either cache some requests to be sent to the
# server, or generate the different status pages (these all land in status()
# in Handler.pm and are handled generic). After all requests (typically only
# one anyway) have been handled that way, finish_connect() will be called and
# if there were any requests to be send to the server, will send them and then
# relay back the answer to the client.

#############################################################################

sub type () { 'proxy'; }

# check_auth_request needs to return a fake client object to signal that
# everything went ok. We return ourselves, and thus we need is_proxy():
sub is_proxy { 0; }

sub version { $VERSION; }
sub build { $BUILD; }

sub _init
  {
  # init my own fields, than call base class _init() to finish it off
  my ($self,$args) = @_;
  
  $self->{_send_cache} = {};
  $self->{_info_cache} = {};
  $self->{_send_id} = 'req0001';
  $self->{_req_remap} = {};
  $self->{debug} = 0;

  # disable checks for files, because they don't exist at the proxy
  $self->{no_file_check} = 1;

  # XXX TODO: we fake ourself as client object
  $self->{name} = 'unknown';

  # we cache test request answers for a maximum of 6 hours
  $self->{_test_cache} = Dicop::Cache->new( timeout => 3600*6 );

  $self->SUPER::_init($args);

  ###########################################################################  
  # set up connector (.e.g. the method we are using to connect server)

  my $cfg = $self->{config};

  $self->_load_connector($cfg, $args);

  my $pid = $$ || 0; my $arch = $^O;

  # get CPU info
  my $cpuinfo = Dicop::Base::cpuinfo($self, $args->{_no_warn});

  # build our auth request that we will use to authenticate ourself to the main server
  $self->{ident} = Dicop::Request->new( id => 'req0001',
   data => "cmd_auth;id_$cfg->{id};version_$VERSION-$BUILD;pid_$pid;arch_$arch$cpuinfo",
   patterns => $self->{request_patterns},
   );

  # init done
  $self;
  }

sub _after_config_read
  {
  # check config for being valid and insert default values
  my ($self,$cfg,$cfgdir,$cfgfile) = @_;

  ###########################################################################
  # set some default config values

  Dicop::Base::cfg_default( $self,
    msg_dir => 'msg',
    def_dir => 'def',
    tpl_dir => 'tpl',
    max_requests => 128,
    msg_file => 'messages.txt',
    patterns_file => 'request.def',
    log_dir => 'logs',
    error_log => 'error_proxy.log',
    server_log => 'proxy.log',
    file_server => 'http://127.0.01/',
    max_request_time => 5,
    self => '/',
    client_architectures => 'linux,os/2,mswin32,armv4l',
    chroot => '',
    name => "dicop-proxy",
    title => "Dicop-Proxy - ",
    );

# mail_server => 'none',

  $self;
  }

sub _load_data
  {
  my $self = shift;

  my $cfg = $self->{config};
  # basic check for keys/values/types
  my $allowed_keys = Dicop::Proxy::Config::allowed_keys();
  my $check = $cfg->check($allowed_keys);

  give_up($check) if defined $check;
  
  $self->{allowed_archs} = $cfg->{client_architectures}
    || give_up ('Need a list of allowed client architectures');
  $self->{allowed_archs} = [ split(/\s*,\s*/, $self->{allowed_archs}) ];

  }

sub pre_connect
  {
  my ($self,$peer,$params) = @_;

  # XXX TODO: this might cause problems with proxy-chaining
  $self->{peeraddress} = $peer;

  # for each connect, reset the send_id etc
  $self->clear_cache();
  }

sub finish_connect
  {
  my ($self,$result) = @_;

  $self->output ("finish_server\n");

  # if $$result is non empty, some error occured or a status page was
  # requested and successfully build
  return $result if $$result ne '';
    
  # if it is empty, send our accumulated requests to the server and
  # return either the response or some error message to the client
  $$result = $self->talk_to_server();

  $result;
  }

#############################################################################

sub check_auth_request
  {
  # check the auth or info request a client/proxy sent us for basic validity
  # Return ref to $client, or error message
  my ($self,$req,$rid,$check_proxy) = @_;

  # XXX TODO: auth request from client should be checked for basic validity
  # How? We do not know which clients are valid. Define valid client range
  # in config file? Check architecture to be known?

  # XXX TODO: In addtion, we can check for the architecture being valid.

  # cheap hack to have a valid client object
  $self;
  }

sub request_auth
  {
  my ($self,$auth,$info) = @_;

  # XXX TODO: auth request from client should be checked for basic validity
  # How? We do not know which clients are valid. Define valid client range
  # in config file? Check architecture to be known?

  return ( {}, '', {});
  }

#############################################################################

sub remap_request_id
  {
  # map from server's response request_id back to what the client sent us
  my ($self,$req_id) = @_;

  $self->{_req_remap}->{$req_id};
  }

sub cache_request
  {
  # takes a request, and adds it to the _send_cache
  # return 1 if we need to send to the server, otherwise 0
  my ($self,$request,$client,$info) = @_;

  # create a new request with a new id for the cache
  my $req = $request->copy();
  my $old_id = $request->request_id();
  my $new_id = ++$self->{_send_id};
  $req->request_id($new_id);
  $self->{_send_cache}->{$new_id} = $req;

  # enter this request into the remap cache so that we can later remap the
  # server's answer back to the client:
  $self->{_req_remap}->{$new_id} = $old_id;

  # in addition to the cached request, we also need to create an info request

  # go through all items in the info cache and if the cached request
  my $info_req;					# the info request
  my $ic = $self->{_info_cache};
  for my $id (keys %$ic)
    {
    my $req = $ic->{$id};
  
    # found the right info request? so remember it and stop 
    $info_req = $req, last if ($req->{id} eq $info->{id});
    }

  if (defined $info_req)
    {
    # we already have one, so simple add the current request to the 'for' field
    $info_req->{for} .= ",$self->{_send_id}";	# this info is for this request
    }
  else
    {
    # don't have one yet, so create a new one
    $info_req = $info->copy();			# copy the auth from client
    $info_req->{cmd} = 'info';			# turn into info request
    $info_req->{for} = $self->{_send_id};	# this info is for this request
    $info_req->{ip} = $self->{peeraddress};	# client's real IP
    $info_req->request_id(++$self->{_send_id});	# give it a new request id
  
    # store the info request in our cache
    $self->{_info_cache}->{$info_req->request_id()} = $info_req;
    }

  1;						# XXX TODO: rc not used anymore
  }

sub build_server_talk
  {
  # create the text that is sent to the server
  my $self = shift;

  # string together request and info requests
  my $txt = $self->{ident}->as_request_string() . "&";
  foreach my $id (sort keys %{$self->{_send_cache}})
    {
    my $req = $self->{_send_cache}->{$id};
    print STDERR "error in request $id: ", $req->error() if $req->error();
    $txt .= ($req->as_request_string()||'') . "&";
    }
  foreach my $id (sort keys %{$self->{_info_cache}})
    {
    my $req = $self->{_info_cache}->{$id};
    print STDERR "error in request $id: ", $req->error() if $req->error();
    $txt .= ($req->as_request_string()||'') . "&";
    }
  $txt =~ s/\&$//;		# remove last &
  $txt;
  }

sub clear_cache
  {
  my $self = shift;

  $self->{_send_cache} = {};
  $self->{_info_cache} = {};
  $self->{_send_id} = 'req0001'; 	# reset id for next send
  $self->{_req_remap} = {};
  $self;
  }
   
sub talk_to_server
  {
  # send anything in cache and the info requests to the server
  my ($self) = @_;
 
  my $txt = $self->build_server_talk();

  my $res = $self->_connect_server(undef,$txt);

  my $response = "<PRE>\nreq0000 099 Proxy localtime ".localtime()."\n";

  if ($res->is_success())
    {
    $self->output($res->content) if $self->{debug} > 1;
    $response .= $res->content;

    # remap now server's responses back to client (any unknown request id is
    # passed through)
    $response =~ s/\b(req\d\d\d\d)(\s+\d)/ ($self->remap_request_id($1) || $1) . $2; /eg;
    }
  else
    {
    # some error occured, send error message to client
    $response .= "req0000 500 Error while talking to upstream server: " . $res->code() . " " . $res->message()."\n";
    }

  # now send what we got from the server back to the client
  $response;
  }

sub output
  {
  my $self = shift;

  return unless $self->{debug} > 0;

  print STDERR join (" ", @_),"\n";
  }

sub _sleeping
  {
  # called by _connect_server()
  return;
  }

sub _die_hard
  {
  # called by _connect_server()
  return;
  }

#############################################################################
# the actual client requests/reports land us here

sub request_test
  {
  my ($self,$request,$client,$info) = @_;

  $self->cache_request($request,$client,$info);
  
  \"";
  }

sub request_work
  {
  # request test case (take it either form cache or ask server)
  my ($self,$request,$client,$info) = @_;

  $self->cache_request($request,$client,$info);

  \"";
  }

sub report
  {
  # client want's to report work or test case result
  my ($self,$request,$client,$info) = @_;

  $self->cache_request($request,$client,$info);

  \"";
  }

sub _client_from_info
  {
  # Not used here, called by Base::Handler::request_file()
  # XXX TODO: this would break if a proxy (instead of a client) connects to us?
  my ($req,$client,$info) = @_;

  (undef,$client,undef);
  }

1; 

__END__

#############################################################################

=pod

=head1 NAME

Dicop::Proxy - A proxy for a Dicop system

=head1 SYNOPSIS

	use Dicop::Proxy;

	$proxy = Dicop::Proxy->new();
	$proxy->parse_client_requests($self,$requests);

=head1 DESCRIPTION

This module includes some routines that make up the logic of the proxy part
of the server.

This is a subclass of Dicop::Handler and overrides only the necc. methods.

This package is used by C<dicopp> to implement a full Dicop-Proxy.

=head1 REQUIRES

perl5.008003, Exporter

=head1 EXPORTS

Exports nothing per default.

=head1 METHODS

=head2 remap_request_id()
  
	my $req_id = $proxy->remap_request_id( $response->request_id() );

Map from server's response request_id back to what the client sent us.

=head2 cache_request()

Takes a request, and adds it to the _send_cache. It also creates a client_info
request, if that isn't already there, otherwise it updates the client info.
Return 1 if we need to send to the server (cache full), otherwise 0.

=head2 build_server_talk()
  
Create the text that is sent to the server by stringing together request and
info requests from the cache.

=head2 clear_cache()

Clear the send cache and the client info list, reset the request id for the
send cache.
  
=head2 new()

Create a new Dicop::Proxy object and init the data fields of it. Called by the
servers init() method.

=head2 talk_to_server()

Uses L<build_server_talk> to build the text for the upstream server, send it
to the server, and then clear the cache and client info list. Returns the
servers answer as text.

=head2 request_test()

Called for each testcase request. 

=head2 request_work()

Called for each work request. 

=head2 request_file()

Called for each file request. 

=head2 report()

Called for each chunk the client reports back.

=head2 type()

Returns the string 'proxy'.

=head2 is_proxy()

Returns true.

=head2 output()

Output a string to STDERR for debugging purposes.

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 1998-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

