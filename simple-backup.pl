#!/usr/bin/perl -w
# 2013-07-02
# A simple backup script that uses rsync.
#
# TODO:
#   - proper CLI arg/flag handling
#   - specifying directories to backup in config

use strict;
use warnings;
use v5.14;
use File::Rsync       qw(new exec);
use File::Spec        qw(rel2abs);
use Config::Simple;
use Getopt::Long;

use constant CONFIG => $ENV{HOME}.'/.simplebackup.conf';


# Check argc.
die "usage: $0 [--compress] [--std] [src-dir] [dst-dir]\n" if scalar(@ARGV) != 3;


$main::args = get_args();

# Set rsync args for the backup and instantiate rsync instance.
$main::rsync_instance = File::Rsync->new({
  archive   => 1,
  acls      => 1,
  xattrs    => 1,
  verbose   => 1,
  exclude   => get_excluded_files(CONFIG),
  compress  => $main::args->{compress}
});


# Switch on user specified args.
while (my ($key, $value) = each %{$main::args})
{
  if ($key eq 'standard' and $value) {
    standard_backup($ARGV[$#ARGV-1], $ARGV[$#ARGV]);
  }
  #TODO: switch on other options
}



### SUBROUTINES ###

# Handle CLI args with Getopt::Long functionality.
#
# return: reference to hash containing flags for each of the possible CLI args
sub get_args
{
  my %args = (
    compress  => '',
    standard  => '',
    config    => ''
  );

  GetOptions(
    'compress'  => \$args{compress},
    'std'       => \$args{standard},
    'cfg'       => \$args{config},
  );

  return \%args;
}

# Get specified excluded files from config and returns a reference to an array containing them.
#
# arg0:   path to config
# return: reference to array of files to be excluded from backup
sub get_excluded_files
{
  my @excluded_files = ();

  my $cfg = new Config::Simple($_[0]) 
    or return \@excluded_files;

  @excluded_files = $cfg->param('Exclude');
  return \@excluded_files;
}

# Checks if user has specified whether or not to use rsync compression via CLI arg.
#
# return: 1 if compression has been specified, else 0.
sub get_compression_flag
{
  return 1 if ($ARGV[$#ARGV-2] ne $ARGV[0] and $ARGV[$#ARGV-2] eq '-z');
  return 0;
}

# Performs a standard backup of source directory to destination.
#
# arg0:   path to source directory
# arg1:   path to destination directory
sub standard_backup
{
  # Get absolute paths to specified directories.
  my $paths = {
    src   => File::Spec->rel2abs($_[0]),
    dest  => File::Spec->rel2abs($_[1])
  };

  # Check to make sure source directory exists.
  -d $paths->{src}
    or die "$0: Cannot find directory: $paths->{src}\n";

  # Perform backup operation.
  $main::rsync_instance->exec($paths)
    or die "$0: backup failed:\n$!\n";
}
