% =========================================================================
%
% calculate all similarities
%
% Inputs:
% ~~~~~~
% conf - the configuration struct with all the relevant paths
% sim_results_file - prefix of the similarity results file to store the results
% align - should run on the aligned version or the not aligned version of the
%         descriptors
% instance - enable multi processes to run simultaneously, so each process
%            part of the data. specify the instance number.
% num_instances - total number of processes to know what splits are in the
%                 responsibility of this instance.                 
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function calculate_all_similarities(conf, sim_results_file, align, instance, num_instances)
    
    % constants
    DEBUG = false % TODO: change to false!!!
    
    META_DATA_FILE = 'meta_and_splits.mat';
        
    % manipulate the sim_results_file to match the parameters
    if (align)
        align_str = '.align.mat';
    else
        align_str= '.not_align.mat';
    end
    sim_results_file = strrep(sim_results_file,'.mat', align_str);
    if (instance > -1)
        tmp = sprintf('.%d.mat', instance);
        sim_results_file = strrep(sim_results_file,'.mat',tmp);
    end
    fprintf('[%s]: similarity results file: %s\n', datestr(now), sim_results_file);

    % build meta data file's name
    meta_data_file = sprintf('%s/%s', conf.meta_data, META_DATA_FILE)
        
    % load meta data
    DB_meta_data = load(meta_data_file);
%     DB_meta_data = 
% 
%     video_labels: [1x3425 double]
%      video_names: {3425x1 cell}
%        mat_names: {3425x1 cell}
%           Splits: [500x3x10 double]

    splitsize = size(DB_meta_data.Splits,1);
    if (DEBUG)
        splitsize = 5;
    end
    
    numsplits = size(DB_meta_data.Splits,3);
    numpairs = numsplits * splitsize;
    
    % initialize sim_results
    sim_results.align = align;
    sim_results.lastsplit = 1;
    sim_results.last_num_in_split = 0;    
    sim_results.y = zeros(numpairs,1);
    sim_results.splitid = zeros(numpairs,1);
    [sim_results.polarity, sim_results.feat, sim_results.issqrt,...
        sim_results.method] = get_similarities_meta_data(conf);
    sim_results.similarity = zeros(size(sim_results.polarity,1), numpairs);
    sim_results.calc_time = zeros(size(sim_results.polarity,1), numpairs);
    sim_results.totaltime = 0;
    sim_results.feat_name = {'CSLBP', 'FPLBP', 'LBP'};
    sim_results.MBGS_params = conf.MBGS_params;
    
    % if the similarity results file already exist, load the data from it
    % and continue from the last place it was stopped
    if (exist(sim_results_file, 'file'))
        fprintf('[%s]: file %s exist, loading file\n', datestr(now), sim_results_file);
        sim_results = load(sim_results_file)
    end
    
    % create LLC and MBGS bases if needed (if the bases are already created 
    % then it will just read it from the disk)
    LLC_MBGS_bases = create_LLC_and_MBGS_bases(conf, DB_meta_data, align);
    
    % run on all splits and update the similarity matrix

    prev_last_num_in_split = sim_results.last_num_in_split + 1;

    for split = sim_results.lastsplit:numsplits
        if ((instance > -1) && (mod(split, num_instances) ~= instance))
            % instance is defined, but this is not my split
            continue;
        end
        
        LLC_bases_for_split = get_LLC_base_for_split(LLC_MBGS_bases, split,...
                    numsplits, splitsize, conf.MBGS_params.num_of_side_splits);
                
        [MBGS_bases_for_split, MBGS_pose_base] = get_MBGS_base_for_split(LLC_MBGS_bases,...
            split, numsplits, splitsize, conf.MBGS_params.num_of_side_splits);

        for num_in_split = prev_last_num_in_split:splitsize
            
            time_start = tic;
            
            next = DB_meta_data.Splits(num_in_split,:,split);
            idx = (split - 1)*splitsize + num_in_split;
            fprintf('[%s]: align = %d, split = %d, num_in_split = %d,  idx = %d\n',...
                datestr(now), align, split, num_in_split, idx); 

            % load descriptors and pose of the first video out of the pair
            name1 = get_video_mat_file_name(DB_meta_data.mat_names{next(1)},align)
            cX1 = load_video_descriptors(conf.DB_root, name1);
            pose1 = get_head_oriented_pose(conf, DB_meta_data.mat_names{next(1)});

            % load descriptors and pose of the second video out of the pair
            name2 = get_video_mat_file_name(DB_meta_data.mat_names{next(2)},align)
            cX2 = load_video_descriptors(conf.DB_root, name2);
            pose2 = get_head_oriented_pose(conf, DB_meta_data.mat_names{next(2)});

            % calculate similarity
            [sim_idx, calc_time_idx] = get_similarities(conf, pose1, pose2,...                                                    
                                                    cX1, cX2, align,...
                                                    instance, LLC_bases_for_split,...
                                                    MBGS_bases_for_split,...
                                                    MBGS_pose_base);
            
            curr_time = toc(time_start);
            
            % update similarity results struct to be stored in the file
            sim_results.similarity(:,idx) = sim_idx; 
            sim_results.calc_time(:,idx) = calc_time_idx;
            sim_results.y(idx) = 2* next(3) - 1; % the labels in the split are 0 and 1
            sim_results.splitid(idx) = split;
            sim_results.lastsplit = split;
            sim_results.last_num_in_split = num_in_split;
            sim_results.totaltime = sim_results.totaltime + curr_time;
            
            % constantly store the similarity results to enable to
            % recontinue from the place we previously stop in case of 
            % failure.
            % remove the the files when you want to
            % recalculate the results from scratch (e.g. change in one
            % of the algorithms or the data)
            save(sim_results_file, '-struct', 'sim_results');
        end
        prev_last_num_in_split = 1; % start from 1 in the next split
    end    
end


% calculate similarity matrix with all of the methods
function [similarity, calc_time] = get_similarities(conf, pose1, pose2,...
                                                    cX1, cX2, align,...
                                                    instance, LLC_bases_for_split,...
                                                    MBGS_bases_for_split,...
                                                    MBGS_pose_base)
    similarity = [];
    calc_time = [];
       
    for j = 1:3;        
        X1 = cX1{j};
        X2 = cX2{j};
    
        issqrt = 0;
        [s1,t1] = get_similarity_internal(conf, pose1, pose2, X1, X2, j,...
                                          issqrt, align, instance,...
                                          LLC_bases_for_split{j},...
                                          MBGS_bases_for_split{j},...
                                          MBGS_pose_base);
                
        % again, now with sqrt
        X1 = sqrt(cX1{j});
        X2 = sqrt(cX2{j});
        
        issqrt = 1;
        [s2,t2] = get_similarity_internal(conf, pose1, pose2, X1, X2, j,...
                                          issqrt, align, instance,...
                                          LLC_bases_for_split{j},...
                                          MBGS_bases_for_split{j},...
                                          MBGS_pose_base);
        
        similarity = [similarity; [s1;s2]];
        calc_time = [calc_time; [t1;t2]];
    end        
end


% calculate the similarity for the given two matrix in all methods
function [similarity, time] = get_similarity_internal(conf, pose1, pose2,...
                                                      X1, X2, feat, issqrt,...
                                                      align, instance, LLC_base,...
                                                      MBGS_base,...
                                                      MBGS_pose_base)
    
    similarity = [];
    time = [];
    
    % basic - first 5, polarity: -1 -1 -1 -1 -1
    if (conf.methods.basic)
        tic;
        [mindist,maxdist,meandist,mediandist,meanmin] = setdist_basics(X1,X2);
        t = toc;
        time = [time, repmat(t,1,5)];
        similarity = [similarity mindist,maxdist,meandist,mediandist,meanmin];
    end
    
    % pose - another 2, polarity -1 -1
    if (conf.methods.pose)
        tic;
        [most_frontal,nearest_pose] = setdist_pose(X1, X2, pose1, pose2);        
        t = toc;
        time = [time, repmat(t,1,2)];
        similarity = [similarity most_frontal,nearest_pose];
    end
    
    % algebraic - another 5, polarity: -1 1 -1 1 1
    if (conf.methods.algebraic)
        tic;
        [max_corr,projection,binet_cauchy,procrustes,norm_f_u1Tu2] = setdist_algebraic(X1,X2);
        t = toc;
        time = [time, repmat(t,1,5)];
        similarity = [similarity max_corr,projection,binet_cauchy,...
                      procrustes,norm_f_u1Tu2];
    end
    
    % CMSM - another 1, polarity 1
    if (conf.methods.CMSM)
        tic;
        cmsm = setdist_CMSM(X1,X2);
        t = toc;
        time = [time, repmat(t,1,1)];    
        similarity = [similarity cmsm];
    end
    
    % pmk - another 2, polarity: 1 1
    if (conf.methods.PMK)
        tic;
        [spmk,spmknorm] = setdist_pmk(conf, X1, X2, feat, align, instance); 
        t = toc;
        time = [time, repmat(t,1,2)];
        similarity = [similarity spmk,spmknorm];
    end
    
    % LLC - another 1, polarity: -1
    if (conf.methods.LLC)
        tic;
        llc = setdist_LLC(X1, X2, LLC_base); 
        t = toc;
        time = [time, repmat(t,1,1)];
        similarity = [similarity llc];
    end
    
    % MBGS 
    if (conf.methods.MBGS || conf.methods.MBGS_sanity)
        tic;
        [s_L2, s_pose, s_sanity] = setdist_MBGS(X1, X2, pose1, pose2,MBGS_base,...
                                               MBGS_pose_base,...
                                               conf.methods.MBGS_sanity,...
                                               conf.MBGS_params);
        t = toc;

        % MBGS - another 8, polarity: 1 1 1 1 1 1 1 1
        if (conf.methods.MBGS)
            time = [time, repmat(t,1,8)];
            similarity = [similarity s_L2.mean,s_L2.median,s_L2.max,s_L2.min,...
                          s_pose.mean,s_pose.median,s_pose.max,s_pose.min];
        end

    	% MBGS sanity - another 4, polarity: 1 1 1 1
        if (conf.methods.MBGS_sanity)
            time = [time, repmat(t,1,4)];
            similarity = [similarity s_sanity.mean,s_sanity.median,s_sanity.max,s_sanity.min];
        end
    end
    
    time = time';
    similarity = similarity';
end


% get similarities meta data: polarity, feature, and issqrt
% note!! this should match exactly the above function get_similarities
function [polarity, feat, issqrt, method] = get_similarities_meta_data(conf)

    % the basic_polarity and basic_method are derived directly from the 
    % get_similarity_internal
    
    basic_method = {};
    basic_polarity = [];
    
    % basic - first 5, polarity: -1 -1 -1 -1 -1
    if (conf.methods.basic)
        basic_method = {basic_method{1:size(basic_method,2)},...
                        'mindist', 'maxdist', 'meandist', 'mediandist', 'meanmin'};
        basic_polarity = [basic_polarity -1 -1 -1 -1 -1];
    end
    
    % pose - another 2, polarity -1 -1
    if (conf.methods.pose)
        basic_method = {basic_method{1:size(basic_method,2)},...
                        'most_frontal', 'neareset_pose'};
        basic_polarity = [basic_polarity -1 -1];
    end
    
    % algebraic - another 5, polarity: -1 1 -1 1 1
    if (conf.methods.algebraic)
        basic_method = {basic_method{1:size(basic_method,2)},...
            'max_corr','projection', 'binet_cauchy', 'procrustes', 'norm_f_u1Tu2'};
        basic_polarity = [basic_polarity -1 1 -1 1 1];
    end
    
    % CMSM another 1, polarity 1
    if (conf.methods.CMSM)
        basic_method = {basic_method{1:size(basic_method,2)},'cmsm'};
        basic_polarity = [basic_polarity 1];
    end
    
    % pmk - another 2, polarity: 1 1
    if (conf.methods.PMK)
        basic_method = {basic_method{1:size(basic_method,2)},'spmk', 'spmknorm'};
        basic_polarity = [basic_polarity 1 1];
    end
    
    % LLC - another 1, polarity: -1
    if (conf.methods.LLC)
        basic_method = {basic_method{1:size(basic_method,2)},'llc'};
        basic_polarity = [basic_polarity -1];
    end
    
    % MBGS - another 8, polarity: 1 1 1 1 1 1 1 1
    if (conf.methods.MBGS)
        basic_method = {basic_method{1:size(basic_method,2)},...
            'MBGS.L2.mean','MBGS.L2.median','MBGS.L2.max','MBGS.L2.min',...
            'MBGS.pose.mean','MBGS.pose.median','MBGS.pose.max','MBGS.pose.min'};
        basic_polarity = [basic_polarity 1 1 1 1 1 1 1 1];
    end

    % MBGS_sanity - another 4, polarity: 1 1 1 1 
    if (conf.methods.MBGS_sanity)
        basic_method = {basic_method{1:size(basic_method,2)},...
            'MBGS.sanity.mean','MBGS.sanity.median','MBGS.sanity.max','MBGS.sanity.min'};
        basic_polarity = [basic_polarity 1 1 1 1];
    end
    
    basic_polarity = basic_polarity';
    
    single_feat_size = size(basic_polarity,1); 
    num_of_features = 3;
    
    % all the N polarities * [issqrt options (0 or 1)] * num_of_features = N * 2 * 3  
    polarity =  repmat(basic_polarity, 2*num_of_features, 1);
    method = repmat(basic_method, 1, 2*num_of_features);
    feat = [ones(single_feat_size*2,1) ; 2*ones(single_feat_size*2,1) ; 3*ones(single_feat_size*2,1)];
    issqrt = repmat([zeros(single_feat_size,1);ones(single_feat_size,1)],num_of_features,1);
        
end

