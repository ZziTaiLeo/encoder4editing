function [stSoStat] = ROCetcmod(o,labels,th)

[sotedo,sind] = sort(o);
slab = labels(sind);
n = length(o);
np = sum(labels>0);
nn = sum(labels<0);

stSoStat.labels = labels;
stSoStat.o = o;
stSoStat.np = np;
stSoStat.nn = nn;
stSoStat.n = n;

stSoStat.tp = zeros(n,1);
stSoStat.tn = zeros(n,1);
stSoStat.fp = zeros(n,1);
stSoStat.fn = zeros(n,1);
stSoStat.nr = zeros(n,1);

for i = n:-1:0,
	stSoStat.tp(i+1) = sum(slab(i+1:end)>0);
	stSoStat.fp(i+1) = sum(slab(i+1:end)<=0);
	stSoStat.tn(i+1) = sum(slab(1:i)<0);
	stSoStat.fn(i+1) = sum(slab(1:i)>=0);
	stSoStat.nr(i+1) = n-i;
end

if np
  stSoStat.recall = stSoStat.tp ./ np;
else
  stSoStat.recall = ones(n+1,1);
end

stSoStat.precision = [stSoStat.tp(1:n) ./ stSoStat.nr(1:n);1];

stSoStat.normfp = stSoStat.fp./nn;

stSoStat.auc = auc(stSoStat.normfp,stSoStat.recall);

[minn,ii] = min(abs(stSoStat.fp/nn - stSoStat.fn/np));
stSoStat.errorateq = (stSoStat.fp(ii) + stSoStat.fn(ii))/n;

if nargin>2,
  [minn,ii] = min(abs(stSoStat.fp/nn - th));
  stSoStat.tpratfprth = stSoStat.tp(ii)/np;
end


