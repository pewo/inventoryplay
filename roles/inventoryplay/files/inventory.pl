#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use File::Basename;
use File::Temp qw/ tempdir /;
use Getopt::Long;
use Data::Dumper;


my $usage = "$0 -d|--directory <directory> -i|--inventory <ansible inventory> ... -i|--inventory=... --debug\n";
my $debug = 0;

#
# Get all servers that next playbook is $pb
# Incoming hash is $hash{$target}=\@arr (playbooks)
# Returns an array.
#

sub get_all_playbooks {
	my($pb) = shift;
	my(%hash) = @_;
	my(@res) = ();

	return(@res) unless ( $pb );
	print "searching for pb: $pb\n" if ( $debug );
	my($target);
	foreach $target ( sort keys %hash ) {
		my($arr) = $hash{$target};
		my($nextpb) = @$arr[0];
		if ( defined($nextpb) ) {
			if ( $nextpb eq $pb ) {
				push(@res,$target);
				shift(@$arr);
				$hash{$target} = $arr;
			}
		}
	}

	return(@res);
}

#
# Read all files in src ( one per target )
# The file contains the order of execution of playbooks.
#
# Example:
#   autopatch.yml
#   bepa.yml
#   site.yml
#   cepa.yml

#
# hash{target}@arr[playbook1, playbook2, playbookn]
#
sub read_all_files($) {
	my($dir) = shift;
	my(%hash);
	return(%hash) unless ( defined($dir) );
	if ( ! -d $dir ) {
		chdir($dir);
		print "chdir($dir): $!\n";
		return(%hash);
	}

	my($file);
	foreach $file ( <$dir/*> ) {
		my($target) = basename($file);
		my(@arr);
		print "Found: $target\n" if ( $debug );
		unless ( open(IN, "<", $file) ) {
			print "Reading $file: $!\n";
			next;
		}
		my($line);
		foreach $line ( <IN> ) {
			next unless ( defined($line) );
			next unless ( $line );
			chomp($line);
			push(@arr,$line);
		}
		close(IN);
		$hash{$target}=\@arr;
	}
	return(%hash);
}


#
# %hash{$run}{playbook}=playbook
# %hash{$run}{targets}=@arr(target,target,target...)
#
sub construct_runs(\%) {
	my($hash) = shift;
	my(%hash) = %$hash;

	my(%playbook);

	my($run) = 0;
	my($found) = 1;
	
	while ( $found ) {
		$found = 0;
		$run++;
	
		my($target);
		foreach $target ( sort keys %hash ) {
			print "Target: $target\n" if ( $debug );
			my($pb) = $hash{$target}[0];
			next unless ( $pb );
			$found++;
			if ( ! exists($playbook{$run}) ) {
				$playbook{$run}{playbook}=$pb;
				print "pb: $pb, run: $run\n" if ( $debug );
				#push(@playbook,$pb . ":" . $run);
				my(@arr) = get_all_playbooks($pb,%hash);
				$playbook{$run}{targets}=\@arr;
			}
		}
	}
	return(%playbook);
}

my $directory   = undef;
my @inventory   = undef;

GetOptions (
	"d|directory=s" => \$directory,
	"i|inventory=s" => \@inventory,
	"debug"  => \$debug,
  ) or die("Error in command line arguments\n");

unless ( defined($directory) and $#inventory > 0 ) {
	die $usage;
}

my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
    $atime,$mtime,$ctime,$blksize,$blocks)
                       = stat($directory);

if ( ! defined($dev) ) {
	print $usage;
	die "Checking $directory $!\n";
}

my(%hash) = read_all_files($directory);

my(%playbook) = construct_runs(%hash);

my($run);
foreach $run ( sort { $a <=> $b } keys %playbook ) {
	print "run $run\n";
	my($playbook) = $playbook{$run}{playbook};
	my($targets) = $playbook{$run}{targets};
	my($subcmd) = "ansible-playbook $playbook";
        foreach ( @inventory ) {
		next unless ( $_ );
		$subcmd .= " -i $_";
	}
	$subcmd .= " -l " . join(",",@$targets);
	print $subcmd . "\n";
	my($rc) = 0;
	$rc = system($subcmd) unless ( $debug );
	print "rc: $rc  ($subcmd)\n\n\n";
}
