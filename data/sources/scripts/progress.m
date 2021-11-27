% =========================================================================
%
% Calculate the progress of all the processes that calculate the similarity
% Should be aligned with the progress.pl script (same location and same
% constants).
%
% Inputs:
% ~~~~~~
% align - should run on the aligned version or the not aligned version of 
%         the descriptors
% num_instances - total number of processes to know what splits are in the
%                 responsibility of this instance
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function progress(align, num_instances)

    % constants
    TMP_RESULTS_DIR = './tmp_results/';
    SRC_DIR = '../src';
    CONFIGURATION_FILE = '../conf.txt';
    SIMILARITY_RESULTS_FILE = 'sim_results.mat';

    % validate the configuration file and the source dir exist
    if (~exist(CONFIGURATION_FILE, 'file'))
        error('conf file %s doesnt exist\n', CONFIGURATION_FILE);
        return;
    end

    if (~exist(SRC_DIR, 'dir'))
        error('source dir %s doesnt exist\n', SRC_DIR);
        return;
    end

    addpath(SRC_DIR);

    %load configuration
    conf = load_configuration(CONFIGURATION_FILE)    

    if (~exist('num_instances', 'var'))
        num_instances = -1;
    end   

    results_file = sprintf('%s%s', TMP_RESULTS_DIR, SIMILARITY_RESULTS_FILE);
    
    [sim_results, cnt_per_instance] = unify_similarity_matrix(conf, results_file, align, num_instances);
    num_set = sum(sim_results.splitid > 0);
    total = size(sim_results.splitid, 1);
    time_per_process = int64(sim_results.totaltime / num_instances);
    [hours, minutes, secs] = parse_total_seconds(time_per_process);
    average_time_per_pair = double(time_per_process)/num_set;

    status_file = sprintf('%s%s', TMP_RESULTS_DIR, 'status.txt');
    fid = fopen(status_file,'w');
    fprintf(fid, ['number of calculated similarities: %d out of %d, '... 
                  'average time per process (hh::mm:ss): %.02d:%.02d:%.02d, ',...
                  'average of %f seconds per pair.\n'],...
             num_set, total, hours, minutes, secs, average_time_per_pair);

    percent_done = 100 * num_set/total;
    estimated_secs = int64((total - num_set) * average_time_per_pair);
    [hours, minutes, secs] = parse_total_seconds(estimated_secs);
    fprintf(fid, 'Finished %.2f%%, estimated time to finish (hh::mm:ss): %.02d:%.02d:%.02d\n',...
            percent_done, hours, minutes, secs);

    fprintf(fid, 'count per instance:\n');
    for j=0:(num_instances-1)
        fprintf(fid, 'instance = %d, count = %d\n', j, cnt_per_instance(j+1));
    end
    fclose(fid);
end

function [hours, minutes, seconds] = parse_total_seconds(total_seconds)
	
    seconds = mod(double(total_seconds),60);
    minutes = floor(double(total_seconds)/60);
    minutes = mod(double(minutes),60);
    hours = floor(double(total_seconds)/3600);

end
