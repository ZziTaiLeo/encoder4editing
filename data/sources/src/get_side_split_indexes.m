% =========================================================================
%
% returns the side split indexes.
% this is to avoid using the background of the test split in the training 
% (to assure the test data is completely unknown in the training phase) we
% use a rotating side split for the background.
%
% Inputs:
% ~~~~~~
% split_number - the test's split number in the range of 1:numsplits
% numsplits - the total number of splits
% splitsize - the size of the split
% num_of_side_splits - number of side splits to use
%
% Outputs:
% ~~~~~~~
% side_splits - the side splits, subset of 1:numsplits
% indexes - a set of indexes for the side split, subset of 1:numsplits*splitsize
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================
function [side_splits, indexes] = get_side_split_indexes(split_number, numsplits,...
                                                        splitsize, num_of_side_splits)
    if (num_of_side_splits >= (numsplits - 1))
        error('num_of_side_splits (%d) >= numsplits (%d) - 1',...
                num_of_side_splits, numsplits);
    end
    indexes = [];
    side_splits = [];
    totsize = splitsize * 2; % num of subjects
    side = split_number; % init side split
    for i = 1:num_of_side_splits
        side = mod(side, numsplits) + 1;
        side_splits = [side_splits side];
        first_index = 1 + (side - 1)*totsize;
        last_index = first_index + totsize - 1;
        splitindex = first_index:last_index;
        indexes = [indexes splitindex];
    end
    
end