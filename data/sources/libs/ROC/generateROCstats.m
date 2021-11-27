% generate the ROC stats in order to build the ROC curve
% TP - true positive
% FP = false positive
function [TP,FP] = generateROCstats(Y,W,filename)

TP = [1;1];
FP = [1;1];

TH = [-inf;sort(W);inf];

numpos = sum(Y>0);
numneg = sum(Y<=0);

for i = 1:length(TH),
  prediction = (W>TH(i))*2-1;
  TP(i) = sum((prediction>0).*(Y>0))./numpos;
  FP(i) = sum((prediction>0).*(Y<=0))./numneg;
end

if nargin>2
  fid = fopen(filename,'w');
  for i = 1:length(TH)
    fprintf(fid,'%.10f %.10f\n',TP(i), FP(i));
  end
  fclose(fid);
end
