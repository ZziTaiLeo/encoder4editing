README
~~~~~~

Use conf.txt to specify the location of the sources, e.g. the location of all external 
libraries, the location of the results files, which similarity methods to run, etc.
The scripts directory contains all the relevant scripts to create the similarity results.
The common usage is:
=> run calc_similarity.pl to create the similarity distances.
=> use progress.pl to monitor the progress of all the processes that run calc_similarity.
=> after calc_similarity is done, use analyze_results.pl to analzed the results.

Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz


Scripts:
~~~~~~~

analyze_results.pl

After running calc_similarity.pl, all the similarity distances per method are stored in
the results files in the results directory defined in the configuration file.
Analyze results will read all the results files, and output a CSV file with the analyzed 
results. The file is stored in the results directory.

=====================================================================================

calc_similarity.pl

A script that calculates the similarities in all pairs in all methods, split by split.
It enables to run several processes in parallel.			 
For example, to run 10 processes on the aligned descriptors run:
calc_similarity.pl 1 10 10
for more info on this script run: 
calc_similarity.pl -h

======================================================================================

create_composite_results.m

An example script on how to take a sub set of the similarities measures and create a 
composite measure that in many cases gives better results.
It contains few examples showing the main concept.

======================================================================================

create_paper_results.m

A matlab wrapper to calculate all the similarity measures, to unify the results from 
all the different instances, and to analyzed the results.
The scripts calc_similarity.pl and analyze_results.pl call it with the relevant parameters.

======================================================================================

print_conf.pl

Prints the current configuration.

======================================================================================

progress.m

A matlab script that unifies all the results created by calc_similarity, and outputs
how many pairs were already calculated, showing the progress of all the processes of 
calc_similarity.pl.

======================================================================================

progress.pl

A wrapper script to run the progress.m - use it to monitor the progress of all the 
processes that run calc_similarity

======================================================================================

run_matlab_bg.csh

A script to run a matlab program in the background.

======================================================================================


