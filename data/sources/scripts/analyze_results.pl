#!/usr/local/bin/perl
#
# Analyze results after finishing calculating all similarity measures
#
# Author: Itay Maoz, October 2010

use strict;
use File::Basename;
use Cwd;

# constants #
my $ACTION = 3;
my $OUT_DIR = "./out";
my $RESULT_FILE = "summarized_results.csv";
my $RESULTS_DIR_ENTRY = "results_dir";
my $SLEEP_INTERVAL_SECS = 5; 
my $CONF_FILE = "../conf.txt";
my $CONF_PARSER = "conf_parser.pm";

#### Main ####

my $align = shift;
my $num_instances = shift;

usage() unless(defined($align) && defined($num_instances) && $num_instances <= 10);

my $cwd = Cwd::cwd();
my $working_dir = dirname($0);
print "going to $working_dir\n";
chdir($working_dir);

require($CONF_PARSER);

my $log_file = "$OUT_DIR/analyzed_results.$align.out";

mkdir($OUT_DIR) if (!(-d $OUT_DIR));

my %conf = parse_configuration($CONF_FILE);
my $results_dir = $conf{$RESULTS_DIR_ENTRY};

my $res_file = $align ? "align" : "not_align";
$res_file = "$results_dir/$res_file.$RESULT_FILE";

if (-f $res_file) {
	print "removing old existing results file: $res_file\n";
	unlink($res_file);
}

#my $cmd = "./run_matlab_bg.csh 'create_paper_results($ACTION,$align,$num_instances,$num_instances);quit' /dev/stdout";
my $cmd = "./run_matlab_bg.csh 'create_paper_results($ACTION,$align,$num_instances,$num_instances);quit' $log_file";
print "$cmd\n";
system("$cmd");

print "waiting for the creation of $res_file\n";
my $total_secs = 0;
while (!(-f "$res_file")) {
	sleep($SLEEP_INTERVAL_SECS);
        $total_secs += $SLEEP_INTERVAL_SECS; # accurate enough...
	my $min = int($total_secs/60);
	my $secs = $total_secs%60;
	my $lastp = show_last_progress($log_file);
	print "waiting... elapsed time is $min minutes and $secs seconds: so far finished $lastp\n";
}

print "showing analyzed results\n";
system("less $res_file");

chdir($cwd);

#### End Main ####

sub usage {
	print "Usage:\n";
	print "~~~~~\n\n";
	print "$0 <align> <total number of processes> \n\n";
	print "<align> - 1 to use the aligned descriptors or 0 to use the not aligned descriptors\n";
	print "<total number of processes> - total number of processes that are running on this data (could be on another server)\n";
	print "constraints: <total number of processes> <= 10\n\n";
	exit(-1);
}

sub show_last_progress {
	my $file = shift;
	open(IN, $file) || die "can not open file $file";
	my $str = "";
	foreach (<IN>) {
		next unless($_ =~ /(calculating similarity measure.*):/);
		$str = $1;
	}
	close(IN);
	return $str;
}
