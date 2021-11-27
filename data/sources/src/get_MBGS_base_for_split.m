% =========================================================================
%
% get the MBGS base for the given split
%
% Inputs:
% ~~~~~~
% LLC_MBGS_bases - the bases: the output of the call to create_LLC_and_MBGS_bases
% split_number - the test's split number in the range of 1:numsplits
% numsplits - the total number of splits
% splitsize - the size of the split
% num_of_side_splits - number of side splits to use
%
% Outputs:
% ~~~~~~~
% desc_bases{j} - 1<=j<=3, the base to use with setdist_MBGS for the given 
%                 split for feature j
% pose_base - the pose base to by the setdist_MBGS for the given split
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function [desc_bases, pose_base] = get_MBGS_base_for_split(LLC_MBGS_bases,...
                    split_number, numsplits, splitsize, num_of_side_splits)    

    [side_splits, indexes] = get_side_split_indexes(split_number, numsplits,...
                                                    splitsize, num_of_side_splits);
    num_indexes = size(indexes, 2);
    fprintf('[%s]: first index = %d, last index = %d, size = %d', datestr(now),...
             indexes(1), indexes(num_indexes), num_indexes);

    for j = 1:3
        desc_bases{j} = LLC_MBGS_bases.descriptors_base{j}(:,indexes);
    end
    pose_base = LLC_MBGS_bases.pose_base(:,indexes);
end
