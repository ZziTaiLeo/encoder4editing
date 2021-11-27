#!/usr/local/bin/perl
#
# Calculates all the similarity measures as defined in the conf.txt file.
# Edit the configuration file to define the different paths, and different 
# methods to use.
#
# Author: Itay Maoz, October 2010

use strict;
use File::Basename;
use Cwd;

# constants #
my $CALC_SIMILARITY_ACTION = 1;
my $OUT_DIR = "./out";

#### Main ####

my $align = shift;
my $nProcs = shift;
my $totalNprocs = shift;
my $startId = shift;
$startId = 0 unless (defined($startId));
usage() unless (defined($align) && defined($nProcs) && defined($totalNprocs) && 
		$align >= 0 && $align <= 1 &&
		($startId + $nProcs) <= $totalNprocs && $totalNprocs <= 10);

my $cwd = Cwd::cwd();
my $working_dir = dirname($0);
print "going to $working_dir\n";
chdir($working_dir);

print "number of processes to run here: $nProcs out of total $totalNprocs\n";

mkdir($OUT_DIR) if (!(-d $OUT_DIR));

for (my $i = $startId; $i < $startId + $nProcs; $i++) {
	my $cmd = "./run_matlab_bg.csh 'create_paper_results($CALC_SIMILARITY_ACTION,$align,$i,$totalNprocs);quit' out/test.$align.$i.out";
	print "$cmd\n";
	system("$cmd");
}

chdir($cwd);

#### End Main ####

sub usage {
	print "Usage:\n";
	print "~~~~~\n\n";
	print "$0 <align> <number of processes to run now> <total number of processes> [start id]\n\n";
	print "<align> - 1 to use the aligned descriptors or 0 to use the not aligned descriptors\n";
	print "<number of processes to run now> - number of processes to start now\n";
	print "<total number of processes> - total number of processes that are running on this data (could be on another server)\n";
	print "[start id] - optional parameter. the id of the first process [0-10], default 0.\n";
	print "constraints: [start id] + <number of processes to run now> <= <total number of processes> <= 10\n\n";
	exit(-1);
}
