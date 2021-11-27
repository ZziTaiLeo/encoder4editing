% =========================================================================
%
% Create Paper Results
% 
% This is the main function to create the paper results.
% It loads the configuration from the cont.txt and executes all the
% experiments.
%
% Inputs:
% ~~~~~~
% action - specify "1" to calculate all similarities or 
%          specify "2" to unify similarities only
%          specify "3" to unify similarities and process results.
%                  if the results are already unified leave num_instance
%                  empty and it will just load the data from the unified file
% align - should run on the aligned version or the not aligned version of 
%         the descriptors
% instance - enable multi processes to run simultaneously, so each process
%            part of the data. specify the instance number.
% num_instances - total number of processes to know what splits are in the
%                 responsibility of this instance.
%                 useful examples: 1, 2, 5, 10 - all give equal share of
%                 load to all instances, as there are 10 splits.
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function create_paper_results(action, align, instance, num_instances)

    % constants
    SRC_DIR = '../src';
    CONFIGURATION_FILE = '../conf.txt';
    SIMILARITY_RESULTS_FILE = 'sim_results.mat';
    CSV_OUTPUT_FILE = 'summarized_results.csv';
    ANALYZED_OUTPUT_FILE = 'analyzed_results.mat';
    BOOSTING = 'boosting';
    LIBSVM = 'libsvm';

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
    conf.methods
    conf.MBGS_params

    % add libraries' paths
    addpath(conf.classifiers);
    boosting = sprintf('%s/%s', conf.classifiers, BOOSTING);
    addpath(boosting);
    
    libsvm = sprintf('%s/%s', conf.classifiers, LIBSVM);
    addpath(libsvm);
    
    addpath(conf.ROC_dir);
    addpath(conf.llc);
    addpath(conf.emgmm);
        
    if (exist('instance', 'var') && ~exist('num_instances', 'var'))
        error('if parameter "instance" exist need to define "num_distances" too');
    end
    
    if (~exist('instance', 'var'))
        instance = -1;
        num_instances = -1;
    end   

    results_file = sprintf('%s/%s', conf.results_dir, SIMILARITY_RESULTS_FILE);
    
    switch (action)
        case 1
            calculate_all_similarities(conf, results_file, align, instance, num_instances);
        case 2
            unify_similarity_matrix(conf, results_file, align, num_instances);
        case 3
            sim_results = unify_similarity_matrix(conf, results_file, align, num_instances);
            if (align)
                align_str = 'align';
            else
                align_str= 'not_align';
            end
            output_csv_file = sprintf('%s/%s.%s', conf.results_dir, align_str, CSV_OUTPUT_FILE);
            analyzed_output_file = sprintf('%s/%s.%s', conf.results_dir, align_str, ANALYZED_OUTPUT_FILE);
            analyze_results(sim_results, output_csv_file, analyzed_output_file,...
                            conf.MBGS_params.num_of_side_splits);
        otherwise
            error('no such action as %d', action);
    end

end
