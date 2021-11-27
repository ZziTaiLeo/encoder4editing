% =========================================================================
%
% Calculates MSM distance
%
% Inputs:
% ~~~~~~
% X1, X2 - the features matrix
%
% Outputs:
% ~~~~~~~
% cmsm - the CMSM distance
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function cmsm = setdist_CMSM(X1,X2)

    mu1 = mean(X1,2);
    mu2 = mean(X2,2);

    X1 = X1-mu1*ones(1,size(X1,2));
    X2 = X2-mu2*ones(1,size(X2,2));

    [U1,S1] = svds(X1,10);
    [U2,S2] = svds(X2,10);

    minn = min(size(U1,2),size(U2,2));
    if minn<10
        U1 = U1(:,1:minn);
        U2 = U2(:,1:minn);
    end
    A = U1'*U2;

    cmsm = svds(A,1);    
end
