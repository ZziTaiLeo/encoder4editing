% =========================================================================
%
% Get video mat file name
% changes the video mat file name to the aligned version if aligned is 1
%
% Inputs:
% ~~~~~~
% mat_file_name - the mat file to use (not aligned)
% aligned - should run on the aligned version or the not aligned version of
%           the descriptors
%
% Outputs:
% ~~~~~~~
% mat_file_name - the mat file to use
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function mat_file_name = get_video_mat_file_name(mat_file_name, aligned)
    if (aligned == 1)
        mat_file_name = strrep(mat_file_name,'video_','aligned_video_');
    end
end