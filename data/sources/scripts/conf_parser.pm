#!/usr/local/bin/perl
#
# Parses the configuration file and returns a key value hash
#
# Author: Itay Maoz, October 2010

use strict;

sub parse_configuration {
	my $conf_file = shift;
	open(IN,"$conf_file") || die "can not open file $conf_file";
	my %hash = ();
	foreach (<IN>) {
	        next if ($_ =~ /^#/);
	        next unless ($_ =~ /(\S+)\s*\=\s*(\S+.*)/);
	        my $key = $1;
	        my $val = $2;
	        #print "$key = $val\n";
		$hash{$key} = $val;
	}
	close(IN);
	return %hash;
}

1;
