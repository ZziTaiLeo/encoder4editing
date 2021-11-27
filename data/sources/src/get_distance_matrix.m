% =========================================================================
%
% Calculates the distance matrix between X1 and X2
%
% Inputs:
% ~~~~~~
% X1, X2 - matrix of descriptors for the videos (or any matrixes).
%
% Outputs:
% ~~~~~~~
% D - the distance matrix between X1 and X2
% D(i,j) = norm(X1(:,i) - X2(:,j));
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function D = get_distance_matrix(X1,X2)
    len1 = size(X1,2);
    len2 = size(X2,2);
    Z1 = sum((X1).^2,1);
    Z2 = sum((X2).^2,1);
    
    %note this is traspose of CLSnn code
    D = (repmat(Z2, len1, 1) + repmat(Z1', 1, len2) - 2*X1'*X2);
    D = sqrt(D);

    % this is almost equals to (but more efficient calculated):

    %    nCols1 = size(X1, 2);
    %    nCols2 = size(X2, 2);
    %    D = zeros(nCols1, nCols2);
    %    for i=1:nCols1
    %        for j=1:nCols2
    %            D(i,j) = norm(X1(:,i) - X2(:,j));
    %        end
    %    end
end