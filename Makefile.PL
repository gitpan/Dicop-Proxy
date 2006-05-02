use ExtUtils::MakeMaker;
require 5.008003;	# we need at least Perl v5.8.3
use strict;
use lib 'lib';          # if we bundled some modules with the
                        # distribution, try to find these first
                        # (otherwise old core modules would crop up)

my $MIN_BASE_BUILD = 0;	# for CPAN releases, wo always have BUILD == 0

sub MY::metafile {
  package MY;
  my $self = shift;
  if (!eval { require YAML; 1 })
  {
    warn ("YAML not installed, will not override META.yml");
    return $self->SUPER::metafile_target(@_);
  };

  require YAML::Node;
  my $node = YAML::Node->new({});

  $node->{name}                 = $self->{DISTNAME};
  $node->{version}              = $self->{VERSION};
  $node->{version_from}         = $self->{VERSION_FROM};
  $node->{license}              = 'gpl';
  $node->{distribution_type}    = 'module';
  $node->{generated_by}         = "$self->{DISTNAME} version $self->{VERSION}";
  $node->{installdirs}          = 'site';
  $node->{requires}             = $self->{PREREQ_PM};

  my $dump = YAML::Dump( $node );

  $dump =~ s/^(.*)$/\t\$(NOECHO) \$(ECHO) "$1" >>META.yml/gm;
  $dump =~ s/>>META\.yml/>META.yml/;

  return "metafile:\n$dump";
}

# for VERSION and BUILD
eval { require Dicop::Proxy; };

if (!defined $Dicop::Proxy::VERSION)
  {
  warn ("\n*********** Error:\n\n");
  die ("  Can't load Dicop::Proxy - make sure you installed Dicop::Base first\n\n");
  }

# SSL does not work atm, so don't bother to check for it:

## check that we have SSL support:
#my $ssl = 0;
#eval { require IO::Socket::SSL; };
#if (defined $IO::Socket::SSL::VERSION)
#  {
#  $ssl++;
#  $ssl ++ if $IO::Socket::SSL::VERSION > 0.95;
#  }
#
#if ($ssl < 2)
#  {
#  warn ("*********** Warning:\n");
#  warn ("  You do not seem to have IO::Socket::SSL installed. SSL support will not be available.\n")
#    if $ssl == 0;
#  warn ("  Need at least IO::Socket::SSL v0.95 for proper SSL support, but found only v$IO::Socket::SSL::VERSION.\n")
#    if $ssl == 1;
#  warn ("  You need to install the latest version of IO::Socket::SLL from http://search.cpan.org/\n");
#  sleep(5);
#  }

use Dicop::Proxy;			# for VERSION and BUILD
my $version = $Dicop::Proxy::VERSION;
# for releases, omit the BETA VERSION
$version .= "_$Dicop::Proxy::BUILD" if $Dicop::Proxy::BUILD > 0;

WriteMakefile(
    'NAME'		=> 'Dicop-Proxy',
    'VERSION'		=> $version,
    'PREREQ_PM'		=> { 
		'Dicop::Base' => 3.02,
		'Digest::MD5' => 2.09,
		'HTML::Tagset' => 3.03,
		'HTTP::Request' => 1.24,
		'Math::BigInt' => 1.77,
		'Net::Server' => 0.86,
		'Time::HiRes' => 1.2,
		'File::Spec' => 0.82,
		'Test::Simple' => 0.47,
		'Linux::Cpuinfo' => 1.7,
    },
    'PREREQ_FATAL' => 1,
);

warn ("\n **** Warning: Need at least Dicop::Base build $MIN_BASE_BUILD, but got only $Dicop::Base::BUILD! ****\n\n")
  unless $Dicop::Base::BUILD >= $MIN_BASE_BUILD;

