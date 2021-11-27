% =========================================================================
%
% loads the video descriptors from the descriptor mat file
%
% Inputs:
% ~~~~~~
% DB_root - the root of the DB with all the descriptors
% name - the short name of the descriptors file
%
% Outputs:
% ~~~~~~~
% cX - contains the descriptors loaded from the given file name
%     cX{1} - CSLBP;
%     cX{2} = FPLBP;
%     cX{3} = LBP;
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function cX = load_video_descriptors(DB_root, name)
    L = load([DB_root '/' name]);
    cX{1} = L.VID_DESCS_CSLBP;
    cX{2} = L.VID_DESCS_FPLBP;
    cX{3} = L.VID_DESCS_LBP;    
end
