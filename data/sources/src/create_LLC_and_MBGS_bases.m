% =========================================================================
%
% Create LLC and MBGS basess
% The bases are built so they are mutually independent - e.g. for split k
% all the examples will be from splits 1:k-1 and from k+1:n
% for example for splits of 500 pairs (1000 videos), and 10 splits, then
% each split will have a base with 9000 faces.
%
% to avoid excessive use of memory, the output will be:
% LLC_MBGS_bases.base{j} - a base with a descriptor from every frame (10,000 
%                         in the above example). 1<=j<=3
% LLC_MBGS_bases.index{i} - the indexes to be used for split i. for the above example:
%                          index{1} will contain indexes 1001:10000 
%                          index{2} will contain indexes [1:1000 2001:10000]
% 
% LLC_MBGS_bases will contain all the bases for LLC and MBGS, so when calling
% the function:
% base = get_LLC_base_for_split(LLC_MBGS_bases, split_number)
%
% the output will be the base to be used for the given split by LLC
%
% and when calling the function:
% base = get_MBGS_base_for_split(LLC_MBGS_bases, split_number)
% 
% the output will be the base to be used for the given split by MBGS
% 
% Note: we preserved the same format to enable this, but eventually we are
% not using those indexes in get_MBGS_base_for_split.m
%
% Inputs:
% ~~~~~~
% conf - the configuration struct with all the relevant paths
% DB_meta_data - the DB_meta_data as loaded from the meta data file
% align - should run on the aligned version or the not aligned version of the
%         descriptors
% replace_existing - the results are saved in a mat file, to avoid
%                    recreating this data every call.
%                    if replace_existing is set, then it will overwrite the
%                    results, otherwise it will read it from the file
% 
% Outputs:
% ~~~~~~~
% LLC_MBGS_bases - will hold the above structure of bases
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function LLC_MBGS_bases = create_LLC_and_MBGS_bases(conf, DB_meta_data, align, replace_existing)

    % constants
    LLC_MBGS_BASE_FILE = 'LLC_and_MBGS_bases';
    
    replace = 0;
    if (exist('replace_existing', 'var'))
        replace = replace_existing;
    end
    
    % build llc_MBGS_base_file file name string
    if (align)
        align_str = 'align.mat';
    else
        align_str= 'not_align.mat';
    end
    llc_MBGS_base_file = sprintf('%s/%s.%s', conf.meta_data, LLC_MBGS_BASE_FILE, align_str);
    
    % if the file exist and replace = 0 just read it from the file
    if (exist(llc_MBGS_base_file, 'file') && replace == 0)
        fprintf('[%s]: LLC_and_MBGS base file exist: %s, replace = %d, loading from file\n',...
                datestr(now), llc_MBGS_base_file, replace);
        LLC_MBGS_bases = load(llc_MBGS_base_file);
        return;
    end
    
    % create the base from scratch    
    if (~exist(llc_MBGS_base_file, 'file'))
        fprintf('[%s]: LLC_and_MBGS base file [%s] doesnt exist - creating\n',...
                datestr(now), llc_MBGS_base_file);
    else
        fprintf('[%s]: LLC_and_MBGS base file [%s] exists - recreating (replace = %d)\n',...
                datestr(now), llc_MBGS_base_file, replace);
    end        

    splitsize = size(DB_meta_data.Splits,1);
    numsplits = size(DB_meta_data.Splits,3);
        
    % initialize LLC_base
    totsize = splitsize*2;    
    for i = 1:numsplits        
        exclude_from = 1 + (i-1)*totsize;
        exclude_to = exclude_from + totsize - 1;
        LLC_MBGS_bases.index{i} = [1:(exclude_from-1) (exclude_to+1):numsplits*totsize];
        %LLC_MBGS_bases.index{i}
    end
    
    for j = 1:3
       LLC_MBGS_bases.descriptors_base{j} = [];        
    end
    LLC_MBGS_bases.pose_base = [];
    
    for split = 1:numsplits
        fprintf('[%s]: creating LLC base. Reading current split %d\n', datestr(now), split);
        for num_in_split = 1:splitsize
            next = DB_meta_data.Splits(num_in_split,:,split);
            
            % load descriptors of the first video out of the pair
            name1 = get_video_mat_file_name(DB_meta_data.mat_names{next(1)},align)
            cX1 = load_video_descriptors(conf.DB_root, name1);
            pose1 = get_head_oriented_pose(conf, DB_meta_data.mat_names{next(1)});

            % load descriptors of the second video out of the pair
            name2 = get_video_mat_file_name(DB_meta_data.mat_names{next(2)},align)
            cX2 = load_video_descriptors(conf.DB_root, name2);
            pose2 = get_head_oriented_pose(conf, DB_meta_data.mat_names{next(2)});
            
            % choose a random frame for each video
            rand1 = floor(rand*size(cX1{1},2))+1;
            rand2 = floor(rand*size(cX2{1},2))+1;
            LLC_MBGS_bases.pose_base = [LLC_MBGS_bases.pose_base,...
                                       pose1(:,rand1), pose2(:,rand2)];
                                   
            % for all descriptors types
            for j = 1:3                
                LLC_MBGS_bases.descriptors_base{j} = [LLC_MBGS_bases.descriptors_base{j},...
                                                    cX1{j}(:,rand1), cX2{j}(:,rand2)];                
            end
        end        
    end
    
    save(llc_MBGS_base_file, '-struct', 'LLC_MBGS_bases');
    
end