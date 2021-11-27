% =========================================================================
%
% Calculate the different algebraic distances
%
% Inputs:
% ~~~~~~
% X1, X2 - the features matrix
%
% Outputs:
% ~~~~~~~
% different similarity measures created by algebraic methods
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% Based on:
% Kernel Grassmannian distances and discriminant analysis for face 
% recognition from image sets
% Tiesheng Wang, a,  and Pengfei Shia, 
%
% =========================================================================

function [max_corr,projection,binet_cauchy,procrustes,sum_projection] = ...
    setdist_algebraic(X1,X2)

    % using only the first 10 projections - the performance doesn't improve
    % when taking more than 10, but calculation time increases
    [U1,S1] = svds(X1,10);
    [U2,S2] = svds(X2,10);

    minn = min(size(U1,2),size(U2,2));
    if minn<10
        U1 = U1(:,1:minn);
        U2 = U2(:,1:minn);
    end
    A = U1'*U2;

    d = eig(A);

    max_corr = d(1);
    projection = norm(U1*U1'-U2*U2');
    binet_cauchy = (det(A))^2;
    procrustes = norm(d);

    % this one is not bad, but not from the sources
    sum_projection = sqrt(sum(sum((A).^2))); 

end
