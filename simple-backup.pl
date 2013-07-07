#!/usr/bin/perl -w
# 2013-07-02
# A simple backup script that uses rsync.
# arg

use strict;
use warnings;
use v5.14;
use File::Rsync   qw(new exec);
use File::Spec    qw(rel2abs);


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

# Check for compression argument and set flag.
my $compress_flag = 0;
if ($ARGV[$#ARGV-2] ne $ARGV[0] and $ARGV[$#ARGV-2] eq '-z') {
  $compress_flag = 1;
}

# Set rsync args for the backup and instantiate rsync instance.
$main::rsync_instance = File::Rsync->new({
  archive   => 1,
  acls      => 1,
  xattrs    => 1,
  verbose   => 1,
  compress  => $compress_flag
});

# Do the backup.
$main::rsync_instance->exec($paths)
  or die "$0: backup failed:\n$!\n";
