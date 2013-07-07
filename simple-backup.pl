#!/usr/bin/perl -w
# 2013-07-02
# A simple backup script that uses rsync.
#
# TODO:
#   - CLI arg/flag handling
#   - specifying directories to backup in config

use strict;
use warnings;
use v5.14;
use File::Rsync       qw(new exec);
use File::Spec        qw(rel2abs);
use Config::Simple;

use constant CONFIG => $ENV{HOME}.'/.simplebackup.conf';


# Check argc.
die "usage: $0 [-z] <src-dir> <dst-dir>\n" if scalar(@ARGV) != 2;

# Get absolute paths to arg directories.
my $paths = {
  src   => File::Spec->rel2abs($ARGV[$#ARGV-1]),
  dest  => File::Spec->rel2abs($ARGV[$#ARGV])
};

# Check to make sure specified source directory exists.
-d $paths->{src} 
  or die "$0: Cannot find directory: $paths->{src}\n";


# Set rsync args for the backup and instantiate rsync instance.
$main::rsync_instance = File::Rsync->new({
  archive   => 1,
  acls      => 1,
  xattrs    => 1,
  verbose   => 1,
  exclude   => get_excluded_files(CONFIG),
  compress  => get_compression_flag()
});

# Do the backup.
$main::rsync_instance->exec($paths)
  or die "$0: backup failed:\n$!\n";



### SUBROUTINES ###

# Get specified excluded files from config and returns a reference to an array containing them.
#
# arg0: path to config
sub get_excluded_files
{
  my @excluded_files = ();

  my $cfg = new Config::Simple($_[0]) 
    or return \@excluded_files;

  @excluded_files = $cfg->param('Exclude');
  return \@excluded_files;
}

# Checks if user has specified whether or not to use rsync compression via CLI arg.
sub get_compression_flag
{
  return 1 if ($ARGV[$#ARGV-2] ne $ARGV[0] and $ARGV[$#ARGV-2] eq '-z');
  return 0;
}
