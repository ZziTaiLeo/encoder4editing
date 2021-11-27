% =========================================================================
%
% Calculate the pose based distances
%
% Inputs:
% ~~~~~~
% X1, X2 - matrix of descriptors for the videos.
% pose1, pose2 - matrix with the 3 rotation angle of the head
% 
% Outputs:
% ~~~~~~~
% most_frontal - finds the most frontal face in X1 and most frontal face in 
%                X2 and returns the norm distnace between them
% nearest_pose - finds two representing faces from each video, the ones
%                with the most similar pose and compare between them
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function [most_frontal, nearest_pose] = setdist_pose(X1, X2, pose1, pose2)

    % most frontal: 
    % the minimum rotation angles of the head is the most frontal
    [min1, most_front_x1] = min(sum(pose1.^2));
    [min2, most_front_x2] = min(sum(pose2.^2));
    
    most_frontal = norm(X1(:, most_front_x1) - X2(:, most_front_x2));

    [index1, index2] = get_nearest_pose(pose1, pose2);
    
    nearest_pose = norm(X1(:, index1) - X2(:, index2));
end

% returns the indexes of the two most similar poses
function [index1, index2] = get_nearest_pose(pose1, pose2)

    D = get_distance_matrix(pose1, pose2);
    % the most similar pair is the one with the smallest distance between
    % the different rotation angles
    min_distance = min(D(:));
    [mini1, mini2] = find(D == min_distance);
    index1 = mini1(1);
    index2 = mini2(1);
end