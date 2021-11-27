#!/usr/local/bin/perl
#
# Prints the current progress of the running process, ran by calc_similarity
#
# Author: Itay Maoz, October 2010

use strict;
use File::Basename;
use Cwd;

# constants #
my $CONF_PARSER = "conf_parser.pm";
my $CONF = "conf.txt";
my $TMP_RESULTS_DIR = "tmp_results";
my $STATUS_FILE = "$TMP_RESULTS_DIR/status.txt";

#### Main ####

my $align = shift;
my $num_instances = shift;

usage() unless(defined($align) && defined($num_instances) && $num_instances <= 10);

my $cwd = Cwd::cwd();
my $working_dir = dirname($0);
print "going to $working_dir\n";
chdir($working_dir);

require($CONF_PARSER);

my $conf_file = "../$CONF";

my %conf = parse_configuration($conf_file);
my $results_dir = "";
$results_dir = $conf{"results_dir"};

($results_dir ne "") || die "results dir is not defined in the configuration file";

print "=> results dir = $results_dir\n";

print "=> removing tmp results dir: $TMP_RESULTS_DIR\n";
mysystem("rm -rf $TMP_RESULTS_DIR");

print "=> creating tmp results dir\n";
mkdir($TMP_RESULTS_DIR);

print "=> copying results to the tmp results dir\n";
mysystem("cp $results_dir/*.mat $TMP_RESULTS_DIR");

print "=> getting the progress status\n";
mysystem("./run_matlab_bg.csh 'progress($align,$num_instances);quit' /dev/null");

print "=> waiting for the progress to finish\n";
do {
	print ".\n";
	sleep(1);
} while (!(-f "$STATUS_FILE"));
print "\n";

open (IN, "$STATUS_FILE") || die "can not open status file $STATUS_FILE";
foreach (<IN>) { print $_; }
close(IN);
print "\n";

chdir($cwd);

#### End Main ####

sub mysystem {
	my $cmd = shift;
	print "$cmd\n";
	system("$cmd");
}

sub usage {
        print "Usage:\n";
        print "~~~~~\n\n";
        print "$0 <align> <total number of processes> \n\n";
        print "<align> - 1 to use the aligned descriptors or 0 to use the not aligned descriptors\n";
        print "<total number of processes> - total number of processes that are running on this data (could be on another server)\n";
        print "constraints: <total number of processes> <= 10\n\n";
        exit(-1);
}

