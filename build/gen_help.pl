#!/usr/bin/perl -w

# Generates the HTML files for in-server display from the pod.

# This script assumes that the following layout is preserved:

# Dicop-Server-3.01/doc
# Dicop-Proxy-3.01/build/		<-- run script here

use strict;

my $topics = {
  '../Dicop-Server-3.01/doc' =>
   [ qw/
    config
    files
    glossary
    / ],
  'doc' =>
   [ qw/
    trouble
    proxy
    dicopp
    / ],
  '.' =>
   [ qw/
   NEW
  / ] };

`cd ..` unless -d 'build' && -d 'lib';

my $text = '';
foreach my $dir (keys %$topics)
  {
  print "At $dir:\n";
  foreach my $topic (@{$topics->{$dir}})
    {
    print "Generating $dir/$topic...";
    my $pod = $dir . '/' . ucfirst($topic);
    $pod .= '.pod' unless -e $pod; 
    my $t = lc($topic);
      `pod2html $pod | perl ../Dicop-Server-3.01/build/fix_help.pl >tpl/help/$t.tpl`;

    # extract the title
    my $doc = read_file("tpl/help/$t.tpl");
    $doc =~ /<!-- topic: (.*?)-->/;
    my $title = $1 || $t;
    $title =~ s/\.\s+$//;		# remove trailing .

    $text .= 
     '<li><a href="##selfhelp_' . lc($topic) . '##">' . ucfirst($title) .  "</a>\n";

    print " done.\n";
    }
  }

print "Generating help topic include file...";
my $file = "tpl/helptopics.inc";

open FILE, ">$file" or die ("Cannot write $file: $!");
print FILE $text;
close FILE;

# clean off temp. files from pod2html
#`rm *.x~~`;
unlink 'pod2htmd.tmp' if -f 'pod2htmd.tmp';
unlink 'pod2htmi.tmp' if -f 'pod2htmi.tmp';

print "All done.\n";

1;

sub read_file
  {
  my $file = shift;

  local $/ = undef,	# slurp mode
  open FILE, "$file" or die ("Cannot read $file: $!");
  my $doc = <FILE>;
  close FILE;
  $doc;
  }
