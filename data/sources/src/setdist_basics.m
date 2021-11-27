% =========================================================================
% 
% Calculates the basic similarity/distance measures accoriding to the
% distance matrix
%
% Inputs:
% ~~~~~~
% X1, X2 - the features matrix
%
% Outputs:
% ~~~~~~~
% different similarity measures based on the distance matrix
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function [mindist,maxdist,meandist,mediandist,meanmin,D] = setdist_basics(X1,X2)

    % Calculate the similarity matrix between X1 and X2
    % D(i,j) = ||X1(:,i) - X2(:,j)|| 
    % Assuming each column X1(:,i) represents a single datum
    % The number of columns in X2 and X2 could be different
    % 

    D = get_distance_matrix(X1,X2);
    mindist = min(D(:));
    maxdist = max(D(:));
    meandist = mean(D(:));
    mediandist = median(D(:));
    meanmin = mean(min(D,[],1)) + mean(min(D,[],2));
end

