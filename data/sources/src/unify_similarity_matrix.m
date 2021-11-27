% =========================================================================
%
% Unify the similarity matrix 
%
% takes all the results of calculate_all_similarities, what was executed by
% each process and creates one struct with all the data unified
%
% Inputs:
% ~~~~~~
% conf - the configuration struct with all the relevant paths
% sim_results_file - prefix of the similarity results file to store the results
% align - should run on the aligned version or the not aligned version of the
%         descriptors
% num_instances - total number of processes to know how many splits to unify
%
% Outputs:
% ~~~~~~~
% sim_results - the unified sim_results
% cnt_per_instance - the number of similarities calculated for each
%                    instance, required for the progress script
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function [sim_results, cnt_per_instance] = unify_similarity_matrix(conf, sim_results_file, align, num_instances)

    if (align)
        align_str = '.align.mat';
    else
        align_str= '.not_align.mat';
    end
    sim_results_file = strrep(sim_results_file,'.mat', align_str);

    % no instances - just load the unified file
    if (num_instances < 0)
        fprintf('[%s]: no need to unify - file %s sim_results_file already unified\n',...
            datestr(now), sim_results_file);
        sim_results = load(sim_results_file)
        return;
    end
    
    % there are num_instances - unify them
    
    % load the first file (with 0) and then just add the rest of the data
    % to it
    instance = 0;
    tmp = sprintf('.%d.mat', instance);
    curr_file = strrep(sim_results_file,'.mat',tmp)
    sim_results = load(curr_file)   
    cnt_per_instance = sim_results.last_num_in_split;
    
    for instance=1:(num_instances-1)
        tmp = sprintf('.%d.mat', instance);
        curr_file = strrep(sim_results_file,'.mat',tmp)
        curr_res = load(curr_file) 
    
        % sanity checks that this is a part of the same matrix
        if (sim_results.align ~= curr_res.align)
            error('sim_results.align (%d) ~= curr_res.align (%d)',sim_results.align, curr_res.align);
        end
        
        % all 3 similarities meta data should be exactly the same - sanity
        if (norm(sim_results.polarity - curr_res.polarity) ~= 0)
            error('sim_results.polarity ~= curr_res.polarity');
        end
        
        if (norm(sim_results.feat - curr_res.feat) ~= 0)
            error('sim_results.feat ~= curr_res.feat');
        end
        
        if (norm(sim_results.issqrt - curr_res.issqrt) ~= 0)
            error('sim_results.issqrt ~= curr_res.issqrt');
        end
        
        sim_results.y = sim_results.y + curr_res.y;
        sim_results.splitid = sim_results.splitid + curr_res.splitid;
        sim_results.similarity = sim_results.similarity + curr_res.similarity;
        sim_results.calc_time = sim_results.calc_time + curr_res.calc_time;
        sim_results.totaltime = sim_results.totaltime + curr_res.totaltime;
        
        % always update to the smallest "last_num_in_split" so in case one
        % of the splits is not fully processed we'll know in the unified
        sim_results.last_num_in_split = min(curr_res.last_num_in_split,...
                                            sim_results.last_num_in_split);
        % update the counter per instance
        cnt_per_instance = [cnt_per_instance curr_res.last_num_in_split];
    end
    
    unified_file = strrep(sim_results_file,'.mat', '.unified.mat')
    save(unified_file, '-struct', 'sim_results');
end

