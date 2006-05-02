#############################################################################
# Dicop::Proxy::Config - define valid config keys
#
# (c) Bundesamt fuer Sicherheit in der Informationstechnik 2003-2006
#
# DiCoP is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License version 2 as published by the Free
# Software Foundation.
#
# See the file LICENSE or L<http://www.bsi.de/> for more information.
#############################################################################

package Dicop::Proxy::Config;
use vars qw($VERSION);
$VERSION = 0.01;	# Current version of this package
require  5.008;		# requires this Perl version or later

use strict;

sub allowed_keys
  {
  # setup the allowed keys and their type

  my $ALLOWED_KEYS = {};
  foreach my $key (qw/ 
   hand_out_work background
   /)
    { $ALLOWED_KEYS->{$key} = 'flag'; }

  foreach my $key (qw/ 
   min_chunk_size
   max_chunk_size
   /)
    { $ALLOWED_KEYS->{$key} = 'minutes'; }

  foreach my $key (qw/ 
   max_request_time
   initial_sleep
   /)
    { $ALLOWED_KEYS->{$key} = 'seconds'; }


  #foreach my $key (qw/ 
  # /)
  #  { $ALLOWED_KEYS->{$key} = 'hours'; }

  foreach my $key (qw/ 
   name
   group
   user
   host
   proto
   chroot
   title
   allow_admin allow_status allow_stats allow_work
   deny_admin deny_status deny_stats deny_work
   error_log
   server_log
   log_level
   client_architectures
   msg_file
   patterns_file
   objects_def_file
   /)
    { $ALLOWED_KEYS->{$key} = 'string'; }
  
  foreach my $key (qw/ 
   mail_admin
   mail_from
   mail_to
   mail_errors
   /)
    { $ALLOWED_KEYS->{$key} = 'email'; }
  
  foreach my $key (qw/ 
   self
   file_server
   server
   /)
    { $ALLOWED_KEYS->{$key} = 'URL'; }
   
#mail_server

  foreach my $key (qw/ 
   port
   require_client_build
   max_requests
   id
   /)
    { $ALLOWED_KEYS->{$key} = 'int'; }
  
  foreach my $key (qw/ 
   require_client_version
   /)
    { $ALLOWED_KEYS->{$key} = 'float'; }
  
  foreach my $key (qw/ 
   log_dir def_dir msg_dir tpl_dir mailtxt_dir
   /)
    { $ALLOWED_KEYS->{$key} = 'dir'; }

  $ALLOWED_KEYS;
  }

1; 

__END__

#############################################################################

=pod

=head1 NAME

  foreach my $key (qw/ 
   log_dir def_dir msg_dir tpl_dir mailtxt_dir
   /)
    { $ALLOWED_KEYS->{$key} = 'dir'; }

  $ALLOWED_KEYS;
  }

1; 

__END__

#############################################################################

=pod

=head1 NAME

Dicop::Server::Config - define valid config keys

=head1 SYNOPSIS

	use Dicop::Server::Config;
	use Dicop::Config;

	my $config = Dicop::Config->new('data/server.cfg', Dicop::Server::Config::allowed_keys() );

=head1 REQUIRES

perl5.008

=head1 EXPORTS

Exports nothing.

=head1 DESCRIPTION

This module contains a method to create the list of allowed config keys.

=head1 METHODS

=head2 allowed_keys()

	$allowed_keys = Dicop::Server::Config::allowed_keys();

=head1 BUGS

None known yet.

=head1 AUTHOR

(c) Bundesamt fuer Sicherheit in der Informationstechnik 2003-2006

DiCoP is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

See L<http://www.bsi.de/> for more information.

=cut

