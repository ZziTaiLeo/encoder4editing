% =========================================================================
%
% Gets the pose matrix with the 3 rotation angles of the head
%
% Inputs:
% ~~~~~~
% conf - the configuration struct with all the relevant paths
% name - the short name of the descriptors file
%
% Outputs:
% ~~~~~~~
% pose - the 3xn matrix where each vector represents the 3 angles of the 
%        head for the given frame.
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function pose = get_head_oriented_pose(conf, name)
    head_name = strrep(name, '/video', '');
    head_name = [conf.headpose '/headorient_apirun_' head_name];
    head_struct = load(head_name);
    pose = head_struct.headpose;
end