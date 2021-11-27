% =========================================================================
%
% Calculate the pmk distance
%
% this is a wrapper for using the precompiled binaries at the libs/pmk folder.
% the library was downloaded from http://people.csail.mit.edu/jjl/libpmk
% for more info see libs/pmk/README.txt
%
% Inputs:
% ~~~~~~
% conf - the configuration struct with all the relevant paths 
% X1, X2 - the features matrix
% feat - feature type (1,2, or 3) to represent the type of descriptors
% align, instance - see calculate_all_similarities for their meaning.
%                   they are needed here for enabling running this in
%                   several processes in parallel. 
%                   each (align/instance) will have its own files so no
%                   races on the same files
% force_hierarchical_clusterer - specify that to force running the
%                   hierarchical clusterer. the assumption is that in each 
%                   feature the clustering will be similar and therefore, 
%                   in order to achive faster calculations avoid running 
%                   the clusterer every invocation.
%                   therefore if the clusters' file exist for the current 
%                   feature it is not clustered again.
%                   set this flag to true in order to force clustering.
%
% Outputs:
% ~~~~~~~
% spmk,spmknorm - the pmk distance (normalized/not normalized)
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% Based on:
% http://people.csail.mit.edu/jjl/libpmk
%
% =========================================================================

function [spmk,spmknorm] = setdist_pmk(conf, X1, X2, feat, align, instance,...
    force_hierarchical_clusterer)

    % constants
    HIERAR_CMD = 'hierarchical-cluster-point-set.out';
    CLUSTERS_TO_PYRAMID_CMD = 'clusters-to-pyramids.out';
    PYRAMID_CMD = 'pyramid-match-kernel.out';
    
    TRAINING_FILE = 'training.psl';
    PAIRS_FILE = 'pairs.psl';
    CLUSTERS_FILE = 'clusters.hc';
    PYRAMIDS_FILE = 'pyramids.mrh';
    OUTPUT_FILE = 'output.kern';
    
    NUM_OF_LEVELS = 4;
    NUM_OF_BRANCH = 30;
    
    % if not specified, don't run hierarchical clusterer.
    % the default value is false
    if (~exist('force_hierarchical_clusterer', 'var'))
        force_hierarchical_clusterer = false;
    end 
    
    if (force_hierarchical_clusterer)
        fprintf('[%s]: force_hierarchical_clusterer is set.\n', datestr(now));
    end
 
%   Binaries API:
%    
%   Usage: ./hierarchical-cluster-point-set.out input.psl output.hc levels branch
% 
%     <input.psl>: A PointSetList file, where each PointSet contains
%                  features for one image
%     <output.hc>: The result of running HierarchicalClusterer on the input
%     <levels>:    (int) Number of levels in the cluster tree
%     <branch>:    (int) The branch factor of the cluster tree
%
%
%   Usage: ./clusters-to-pyramids.out data.psl clusters.hc output.mrh
% 
%     <data.psl>:      The PointSetList we want to make pyramids for.
%     <clusters.hc>:   The result of running HierarchicalClusterer
%     <output.mrh>:    Where to write the pyramids to
%
%
%   Usage: ./pyramid-match-kernel.out input.mrh output.kern
% 
%     <input.mrh>:  Input pyramids
%     <output.kern>: Where to write the resulting kernel to

    % commands
    hierar_cmd = sprintf('%s/%s', conf.pmk, HIERAR_CMD);
    clusters_to_pyramid_cmd = sprintf('%s/%s', conf.pmk, CLUSTERS_TO_PYRAMID_CMD);
    pyramid_cmd = sprintf('%s/%s', conf.pmk, PYRAMID_CMD);
    
    %files
    files_prefix = sprintf('%s/feat_%d.align_%d.instance_%d.', conf.pmk_scratch,...
        feat, align, instance);

    training_file = sprintf('%s%s', files_prefix, TRAINING_FILE);
    pairs_file = sprintf('%s%s', files_prefix, PAIRS_FILE);
    clusters_file = sprintf('%s%s', files_prefix, CLUSTERS_FILE);
    pyramid_file = sprintf('%s%s', files_prefix, PYRAMIDS_FILE);
    output_file = sprintf('%s%s', files_prefix, OUTPUT_FILE);
   
    % run hierarchical clusterer if needed
    run_hier = force_hierarchical_clusterer;
    if (~exist(clusters_file, 'file'))
        fprintf('[%s]: clutsters file %s does not exist, creating.\n',... 
            datestr(now), clusters_file);
        run_hier = true;     
    end
    
    if (run_hier)
        hierarchical_cluster(hierar_cmd, training_file, clusters_file,...
            NUM_OF_LEVELS, NUM_OF_BRANCH, {X1,X2});
    end
    
    % create pmk point set    
    create_pmk_point_set(pairs_file,{X1,X2});
    
    % use the vocabulary tree to create a pyramid for each image 
    cmd = sprintf('%s %s %s %s', clusters_to_pyramid_cmd, pairs_file,...
        clusters_file, pyramid_file);
    mysystem(cmd);

    % compute the kernel values from the pyramids 
    cmd = sprintf('%s %s %s', pyramid_cmd, pyramid_file, output_file);
    mysystem(cmd);
    
    % read the output file and return result
    K = read_kernel_matrix(output_file)

    spmk = K(1,2);
    spmknorm = spmk./sqrt(K(1,1)*K(2,2));

end


% run the hierarchical clusterer
% run hierarchical k-means to generate a vocabulary tree 
function hierarchical_cluster(hierar_cmd, training_file, clusters_file,...
    levels, branch, cX)
    create_pmk_point_set(training_file, cX);
    cmd = sprintf('%s %s %s %d %d', hierar_cmd, training_file, clusters_file,...
        levels, branch);
    mysystem(cmd);
end


% create pmk point set and store it to a temporary file
function create_pmk_point_set(fname,cX)

    % Format
    % (int32) N, the number of PointSets
    % (int32) f, the dim of every point in this PointSetList
    % For each PointSet:
    % (int32) The number of Points in this PointSet
    % For each point in this PointSet:
    % (Point) The point itself (generally, float * f)
    % Then, again for each Point in this PointSet:
    % (float) The weight of the Point


    fid = fopen(fname,'w');

    %fprintf(fid,'%i %i ',length(cX),size(cX{1},1));
    fwrite(fid,[length(cX),size(cX{1},1)], 'int');

    for i = 1:length(cX),
        %fprintf(fid,'%i ',size(cX{i},2));
        fwrite(fid,size(cX{i},2), 'int');
        %fprintf(fid,'%f ',cX{i}(:));
        fwrite(fid, cX{i}(:), 'float');
        %fprintf(fid,'%f ',ones(size(cX{i},2),1));
        fwrite(fid, ones(size(cX{i},2),1), 'float');
    end

    fclose(fid);

end
    

function K = read_kernel_matrix(fname)

    fid = fopen(fname,'r');

    % Format
    % (int32) N, the number of rows (and cols)
    % (1 * double) row 0 (just k[0][0])
    % (2 * double) row 1
    % ...
    % (N * double) row N-1

    N = fread(fid,1,'int32');
    K = zeros(N);
    for i = 1:N,
        for j = 1:i,
            K(i,j) = fread(fid,1,'double');
            K(j,i) = K(i,j);
        end
    end

    fclose(fid);
end

function mysystem(cmd)
    %fprintf('[%s]: running command: %s\n', datestr(now), cmd);
    system(cmd);
end