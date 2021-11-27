#!/usr/local/bin/perl
#
# Prints the configuration file.
#
# Author: Itay Maoz, October 2010

use strict;
use Data::Dumper;
use File::Basename;
use Cwd;

my $CONF_PARSER = "conf_parser.pm";
my $CONF_FILE = "../conf.txt";

my $cwd = Cwd::cwd();
my $working_dir = dirname($0);
print "going to $working_dir\n";
chdir($working_dir);

require($CONF_PARSER);

my %hash = parse_configuration($CONF_FILE);

chdir($cwd);
#print Dumper(\%hash);

foreach my $key (sort keys %hash) {
	print "\t'$key' => '$hash{$key}'\n";
}
