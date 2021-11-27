% =========================================================================
%
% Calculates the MBGS distances.
% See the paper "Face Recognition in Unconstrained Videos with Matched
% Background Similarity" for more info on the MBGS method
%
% calculates the different flavors of the MBGS algorithm:
% L2, and by pose. each has mean, median, max, min
%
% Inputs:
% ~~~~~~
% X1 and X2 - the descriptor matrixes of given to videos
% pose1, pose2 - matrix with the 3 rotation angle of the head
% background - the background set. a set of descriptors of different
%              faces, where they should all be different from the subjects
%              in the current split (subjects in X1 and X2 are not in the
%              background)
% background_pose - the pose background set. the indexes match, so finiding
%                   the most similar poses in the background_pose, and then
%                   taking the these indexes from the background descriptors
% do_sanity - calculate also the sanity MBGS with the entire background.
%             this argument enables to ignore it as usually it gives worse 
%             results in more time.
%
% Outputs:
% ~~~~~~~
% stats_L2, stats_pose, stats_sanity
% each has mean, median, max, min
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function [stats_L2, stats_pose, stats_sanity] = setdist_MBGS(X1, X2, pose1,...
                                                pose2, background,...
                                                background_pose, do_sanity,...
                                                MBGS_params)

    % constants
    MBGS_TYPE_KNN = 1;
    MBGS_TYPE_FIXED_BG_SIZE = 2;
    MBGS_TYPE_DOUBLE_FIXED_BG = 3;
    MBGS_TYPE_KNN_FIXED_BG_COMBINED = 4;

    LEGAL_TYPES = [MBGS_TYPE_KNN,MBGS_TYPE_FIXED_BG_SIZE,...
                   MBGS_TYPE_DOUBLE_FIXED_BG,MBGS_TYPE_KNN_FIXED_BG_COMBINED];

    if (size(find(LEGAL_TYPES == MBGS_params.type), 2) ~= 1)
        error('invalid MBGS type: %d', MBGS_params.type);
    end        
    
    % ensure MBGS_params.bg_size is smaller than or equals to the entire 
    % background size
    allowed_bg_size = MBGS_params.bg_size;
    if (MBGS_params.type == MBGS_TYPE_DOUBLE_FIXED_BG)
        allowed_bg_size = 2 * MBGS_params.bg_size;
    end
    if (allowed_bg_size > size(background,2))
        error('MBGS_params.bg_size %d > entire background size %d',...
               MBGS_params.bg_size, size(background,2));
    end        
                                           
    % for the case the video has more frames than background size take a
    % subset of X1 and X2. 
    % it is very rare if at all, usually: size(X1,2) << size(background,2)    
    
    size1 = min(size(X1,2), size(background,2));
    X1 = X1(:,1:size1);
    pose1 = pose1(:,1:size1);    
    
    size2 = min(size(X2,2), size(background,2));
    X2 = X2(:,1:size2);
    pose2 = pose2(:,1:size2);    
    
    % find the closest background sets out of the descriptors with the
    % nearest *descriptors*
    
    switch (MBGS_params.type)
        case MBGS_TYPE_KNN
            set1 = get_nearset_set(X1, background, background, MBGS_params.knn);
            set2 = get_nearset_set(X2, background, background, MBGS_params.knn);
            stats_L2 = get_stats(X1, X2, set1, set2);
        case MBGS_TYPE_FIXED_BG_SIZE
            set1 = get_nearset_bounded_set(X1, background, background, MBGS_params.bg_size);
            set2 = get_nearset_bounded_set(X2, background, background, MBGS_params.bg_size);
            stats_L2 = get_stats(X1, X2, set1, set2);
        case MBGS_TYPE_DOUBLE_FIXED_BG
            set1 = get_nearset_bounded_set(X1, background, background, MBGS_params.bg_size);
            set2 = get_nearset_bounded_set(X2, background, background, MBGS_params.bg_size);
            stats1 = get_stats(X1, X2, set1, set2);
            set1 = get_nearset_bounded_set(X1, background, background, MBGS_params.bg_size * 2);
            set2 = get_nearset_bounded_set(X2, background, background, MBGS_params.bg_size * 2);
            stats2 = get_stats(X1, X2, set1, set2);            
            stats_L2 = combine_stats(stats1, stats2);
        case MBGS_TYPE_KNN_FIXED_BG_COMBINED
            set1 = get_nearset_set(X1, background, background, MBGS_params.knn);
            set2 = get_nearset_set(X2, background, background, MBGS_params.knn);
            stats1 = get_stats(X1, X2, set1, set2);
            set1 = get_nearset_bounded_set(X1, background, background, MBGS_params.bg_size);
            set2 = get_nearset_bounded_set(X2, background, background, MBGS_params.bg_size);
            stats2 = get_stats(X1, X2, set1, set2);            
            stats_L2 = combine_stats(stats1, stats2);
        otherwise
            error('invalid type: %d', MBGS_params.type);
    end
    
    stats_pose = stats_L2;
    
    % find the closest background sets out of the descriptors with the
    % nearest *poses*
    switch (MBGS_params.type)
        case MBGS_TYPE_KNN
            set1 = get_nearset_set(pose1, background_pose, background, MBGS_params.knn);
            set2 = get_nearset_set(pose2, background_pose, background, MBGS_params.knn);
            stats_pose = get_stats(X1, X2, set1, set2);
        case MBGS_TYPE_FIXED_BG_SIZE
            set1 = get_nearset_bounded_set(pose1, background_pose, background, MBGS_params.bg_size);
            set2 = get_nearset_bounded_set(pose2, background_pose, background, MBGS_params.bg_size);
            stats_pose = get_stats(X1, X2, set1, set2);
        case MBGS_TYPE_DOUBLE_FIXED_BG
            set1 = get_nearset_bounded_set(pose1, background_pose, background, MBGS_params.bg_size);
            set2 = get_nearset_bounded_set(pose2, background_pose, background, MBGS_params.bg_size);
            stats1 = get_stats(X1, X2, set1, set2);
            set1 = get_nearset_bounded_set(pose1, background_pose, background, MBGS_params.bg_size * 2);
            set2 = get_nearset_bounded_set(pose2, background_pose, background, MBGS_params.bg_size * 2);
            stats2 = get_stats(X1, X2, set1, set2);
            stats_pose = combine_stats(stats1, stats2);
        case MBGS_TYPE_KNN_FIXED_BG_COMBINED
            set1 = get_nearset_set(pose1, background_pose, background, MBGS_params.knn);
            set2 = get_nearset_set(pose2, background_pose, background, MBGS_params.knn);
            stats1 = get_stats(X1, X2, set1, set2);
            set1 = get_nearset_bounded_set(pose1, background_pose, background, MBGS_params.bg_size);
            set2 = get_nearset_bounded_set(pose2, background_pose, background, MBGS_params.bg_size);
            stats2 = get_stats(X1, X2, set1, set2);
            stats_pose = combine_stats(stats1, stats2);
        otherwise
            error('invalid type: %d', MBGS_params.type);
    end
    

    % calc sanity MBGS - use the entire background - much more expensive in
    % calculation time, and gives a bit worse results
    if (do_sanity)
        stats_sanity = get_stats(X1, X2, background, background);
    else
        stats_sanity = 'ignore';
    end
end

% for each vector X(:,i) find the knn nearest vector in the background
% and return it from the background_set
function nearset_set = get_nearset_set(X, background, background_set, knn)
    sPARAMS.k = knn;
    Model = CLSnn(background, [1:size(background, 2)]', sPARAMS);
    [labels, weights, firstindeces] = CLSnnC(X, Model);
    firstindeces = firstindeces(:,1:knn);
    index_to_use = unique(firstindeces);
    nearset_set = background_set(:,index_to_use);
end

% same as get_nearset_set, but return it with a fixed bgsize, where it will
% contain all the nearest neighbors. 
% the set will first be filled with the nearest neighbor of each frame in X
% (removing duplicates).
% then it will be filled with the second nearest neighbor of each frame in
% X, and so on until the size of the nearest set reaches the bgsize.
% bgsize should be smaller than the background size
function nearset_set = get_nearset_bounded_set(X, background, background_set, bgsize)
    Model = CLSnn(background, [1:size(background, 2)]');
    [labels, weights, firstindeces] = CLSnnC(X, Model);
    index_to_use = [];
    
    [s1,s2] = size(firstindeces);
    for i = 1:s2
        if (size(index_to_use,1) >= bgsize)
            break;
        end
        for j = 1:s1
            index_to_use = [index_to_use ; firstindeces(j,i)];
            index_to_use = unique(index_to_use);
            if (size(index_to_use,1) >= bgsize)
                break;
            end
        end
    end
    
    nearset_set = background_set(:,index_to_use);
end

% get stats: train the svm and calculate the statistics function on the
% results
function stats = get_stats(X1, X2, set1, set2)
    y1 = [ones(size(X1,2), 1);-ones(size(set1,2), 1)];
    y2 = [ones(size(X2,2), 1);-ones(size(set2,2), 1)];
    
    model = CLSlibsvm([X1, set1], y1);
    [ry,rw1] = CLSlibsvmC(X2, model);
    
    model = CLSlibsvm([X2, set2], y2);
    [ry,rw2] = CLSlibsvmC(X1, model);
    
    stats = calc_stats(rw1, rw2);    
end

% calculates the average between the stat on rw1 and rw2
function stats = calc_stats(rw1, rw2)
    stats.mean = (mean(rw1) + mean(rw2))/2;
    stats.median = (median(rw1) + median(rw2))/2;
    stats.max = (max(rw1) + max(rw2))/2;
    stats.min = (min(rw1) + min(rw2))/2;
end

% combine two stats results - average them
function stats = combine_stats(stats1, stats2)
    stats.mean = (stats1.mean + stats2.mean)/2;
    stats.median = (stats1.median + stats2.median)/2;
    stats.max = (stats1.max + stats2.max)/2;
    stats.min = (stats1.min + stats2.min)/2;
end