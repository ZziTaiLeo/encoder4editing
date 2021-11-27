function [Model] = CLSlibsvm(Xtrain,Ytrain,sPARAMS);

Xtrain = Xtrain';

if nargin<3
  SETPARAMS = 1;
elseif isempty(sPARAMS)
  SETPARAMS = 1;
else
  SETPARAMS = 0;
end

if SETPARAMS
  sPARAMS.KERNEL = 0;
  sPARAMS.C = 1;
%    sPARAMS.C = 1000;
% sPARAMS.C = intmax;
end

if ~isfield(sPARAMS,'additionalstring')
  sPARAMS.additionalstring = '';
end

if ~isfield(sPARAMS,'posweight')
  sPARAMS.posweight = -1;
end

if ~isfield(sPARAMS,'probability')
  sPARAMS.probability = 0;
end

if ~isfield(sPARAMS,'additionalstring')
  sPARAMS.additionalstring = '';
end

if ~isfield(sPARAMS,'regression')
  sPARAMS.regression = 0;
end

if ~sPARAMS.probability,
  probstring = '-b 0 ';
else
  probstring = '-b 1 ';
end

if ~sPARAMS.regression,
  basicstring = ['-s 0 '];
else
  basicstring = ['-s 3 '];
end

if sPARAMS.C>=0,
  cstring = ['-c ' num2str(sPARAMS.C) ' '];
else
  cstring = '';
end

if sPARAMS.posweight>=0,
  weightstring = ['-wi ' num2str(sPARAMS.posweight) ' '];
else
  weightstring = '';
end

switch sPARAMS.KERNEL,
  case 0, %linear
    kernelstring = '-t 0 ';
  case 1, %poly with no const
    kernelstring = ['-t 1 -g 1 -r 0 -d ' num2str(sPARAMS.DEGREE) ' '];
  case 2, %poly
    kernelstring = ['-t 1 -g 1 -r ' num2str(sPARAMS.COEF) ' -d ' num2str(sPARAMS.DEGREE) ' '];
  case 3, %rbf
    kernelstring = ['-t 2 -g ' num2str(sPARAMS.GAMMA) ' '];
end

paramstring = [basicstring cstring kernelstring weightstring ...
      probstring sPARAMS.additionalstring];
Model = svmtrain(Ytrain,Xtrain,paramstring);
%Model.paramstring = paramstring;
first = find(Ytrain ~= 0);
%Model.FirstLabel = Ytrain( first(1) );

if isfield(sPARAMS,'saveflag'),
  r = 10; 
  save(sPARAMS.saveflag,'r');
end
