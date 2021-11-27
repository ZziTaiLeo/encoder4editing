% =========================================================================
%
% Calculates the LLC distance
%
% Inputs:
% ~~~~~~
% X1 and X2 - the descriptor matrixes of given to videos
% base - the LLC base
% knn - how many knn to use in LLC, default is 5
%
% Outputs:
% ~~~~~~~
% llc is the distance between the 2 sparse represntations of X1 and X2 
% using the max coefficient of the same base
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% Based on the code from Jinjun Wang, see LLC_coding_appr in the external
% libraries.
%
% =========================================================================

function llc = setdist_LLC(X1, X2, base, knn)
    
    % constants
    DEFAULT_KNN = 5;
    
    if (~exist('knn', 'var'))
        knn = DEFAULT_KNN;
    end

    M1 = LLC_coding_appr(base',X1',knn);
    M2 = LLC_coding_appr(base',X2',knn);
    max_coeff1 = max(M1);
    max_coeff2 = max(M2);
    
    llc = norm(max_coeff1(:) - max_coeff2(:));
end