% There are some examples here and other examples can be thought of and
% created.
%
% Inputs:
% ~~~~~~
% sim_results - the similarity results structure as was calculated in 
%               calculate_all_similarities, i.e. loading the stored value 
%               or the return value of unify_similarity_matrix()
% analyzed_results - the output of analyze_results that matches the above 
%                    sim_results, i.e. a matrix that contains the 
%                    analyzed results. A single row for every similarity 
%                    measure containing:
%                    [number, avg, se, roc_auc, roc_err]
%
% Outputs:
% ~~~~~~~
% composite_results - a structure with the composite results
%
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================
function composite_results = create_composite_results(sim_results, analyzed_results)

    % constants
    SRC_DIR = '../src';
    CONFIGURATION_FILE = '../conf.txt';
    BOOSTING = 'boosting';
    LIBSVM = 'libsvm';
    
    % validate the configuration file and the source dir exist
    if (~exist(CONFIGURATION_FILE, 'file'))
        error('conf file %s doesnt exist\n', CONFIGURATION_FILE);
        return;
    end
    
    if (~exist(SRC_DIR, 'dir'))
        error('source dir %s doesnt exist\n', SRC_DIR);
        return;
    end

    addpath(SRC_DIR);
    
    %load configuration
    conf = load_configuration(CONFIGURATION_FILE)
    
    % add libraries' paths
    addpath(conf.classifiers);
    boosting = sprintf('%s/%s', conf.classifiers, BOOSTING);
    addpath(boosting);
    
    libsvm = sprintf('%s/%s', conf.classifiers, LIBSVM);
    addpath(libsvm);

    sz = size(sim_results.method,2);
    exmpale_number = 1;
    
    % Example 1:
    fprintf('[%s]: 1. Calculating for MBGS only, all 3 descriptors with sqrt\n',...
            datestr(now));
    
    % create index set
    index_set = []; 
    for i = 1:sz
        if (strmatch('MBGS', sim_results.method{i})) 
            index_set = [index_set i];
        end
    end;
    
    % create results struct
    res.name = 'MBGS only, composite of all 3 descriptors with sqrt';
    res.method = create_method(sim_results, index_set);
    [res.avg, res.se] = get_svm_results(sim_results, index_set);     
    composite_results{exmpale_number} = res;    
    exmpale_number = exmpale_number + 1;

% ans = 
%       name: 'MBGS only, composite of all 3 descriptors with sqrt'
%     method: {1x48 cell}
%        avg: 0.7718
%         se: 0.01905

    % Example 2:
    fprintf('[%s]: 2. Calculating for MBGS only, all 3 descriptors without sqrt\n',...
            datestr(now));
        
    % create index set
    index_set = []; 
    for i = 1:sz 
        if (strmatch('MBGS', sim_results.method{i}))
            if (sim_results.issqrt(i) == 0)
                index_set = [index_set i];
            end
        end
    end;
    
    % create results struct
    res.name = 'MBGS only, composite of all 3 descriptors without sqrt';
    res.method = create_method(sim_results, index_set);
    [res.avg, res.se] = get_svm_results(sim_results, index_set);     
    composite_results{exmpale_number} = res;    
    exmpale_number = exmpale_number + 1;

% ans = 
%       name: 'MBGS only, composite of all 3 descriptors without sqrt'
%     method: {1x24 cell}
%        avg: 0.7678
%         se: 0.01844
    
    % Example 3:
    fprintf('[%s]: 3. MBGS, sum_projection and basic with sqrt\n',...
            datestr(now));
        
    % create index set
    index_set = []; 
    for i = 1:sz 
        if (strmatch('MBGS', sim_results.method{i}))
            if (sim_results.issqrt(i) == 0)
                index_set = [index_set i];
            end
        end
        if (findstr('MBGS', sim_results.method{i}) > 0)
            index_set = [index_set i];
        elseif (findstr('dist', sim_results.method{i}) > 0)
            index_set = [index_set i];
        elseif (findstr('meanmin', sim_results.method{i}) > 0)
            index_set = [index_set i];
        elseif (findstr('sum_projection', sim_results.method{i}) > 0)
            index_set = [index_set i];
        end
    end;
    
    % create results struct
    res.name = 'MBGS, sum_projection and basic with sqrt';
    res.method = create_method(sim_results, index_set);
    [res.avg, res.se] = get_svm_results(sim_results, index_set);     
    composite_results{exmpale_number} = res;    
    exmpale_number = exmpale_number + 1;

% ans = 
%       name: 'MBGS, sum_projection and basic with sqrt'
%     method: {1x102 cell}
%        avg: 0.7788
%         se: 0.02224    

    % Example 4:
    fprintf('[%s]: 4. All results with avg >= 0.6\n',...
            datestr(now));
        
    % create index set
    index_set = []; 
    for i = 1:sz
        if (analyzed_results.analyzed_results(i,2) >= 0.6) % avg
            index_set = [index_set i];
        end        
    end;
    
    % create results struct
    res.name = 'All results with avg >= 0.6';
    res.method = create_method(sim_results, index_set);
    [res.avg, res.se] = get_svm_results(sim_results, index_set);     
    composite_results{exmpale_number} = res;    
    exmpale_number = exmpale_number + 1;

% ans = 
% 
%       name: 'All results with avg >= 0.6'
%     method: {1x100 cell}
%        avg: 0.7808
%         se: 0.01921  
   
    % Example 5:
    fprintf('[%s]: 5. All results with avg >= 0.65\n',...
            datestr(now));
        
    % create index set
    index_set = []; 
    for i = 1:sz
        if (analyzed_results.analyzed_results(i,2) >= 0.65) % avg
            index_set = [index_set i];
        end        
    end;
    
    % create results struct
    res.name = 'All results with avg >= 0.65';
    res.method = create_method(sim_results, index_set);
    [res.avg, res.se] = get_svm_results(sim_results, index_set);     
    composite_results{exmpale_number} = res;    
    exmpale_number = exmpale_number + 1;
    
% ans = 
% 
%       name: 'All results with avg >= 0.65'
%     method: {1x33 cell}
%        avg: 0.7744
%         se: 0.01948

    % Example 6:
    fprintf('[%s]: 6. All results with avg >= 0.6, no sqrt\n',...
            datestr(now));
        
    % create index set
    index_set = []; 
    for i = 1:sz
        if (analyzed_results.analyzed_results(i,2) >= 0.6 && sim_results.issqrt(i) == 0)
            index_set = [index_set i];
        end        
    end;
    
    % create results struct
    res.name = 'All results with avg >= 0.6, no sqr';
    res.method = create_method(sim_results, index_set);
    [res.avg, res.se] = get_svm_results(sim_results, index_set);     
    composite_results{exmpale_number} = res;    
    exmpale_number = exmpale_number + 1;
    
% ans = 
% 
%       name: 'All results with avg >= 0.6, no sqr'
%     method: {1x52 cell}
%        avg: 0.7744
%         se: 0.01948
    
    % Example 7:
    fprintf('[%s]: 7. No sqrt for MBGS, pose base, basic, max_corr, projection, procrustes\n',...
            datestr(now));
        
    % create index set
    index_set = []; 
    for i = 1:sz
        if (sim_results.issqrt(i) == 1)
            continue;
        end
        if (findstr('MBGS', sim_results.method{i}) > 0)
            index_set = [index_set i];
        elseif (findstr('dist', sim_results.method{i}) > 0)
            index_set = [index_set i];
        elseif (findstr('meanmin', sim_results.method{i}) > 0)
            index_set = [index_set i];
        elseif (findstr('most_frontal', sim_results.method{i}) > 0)
            index_set = [index_set i];
        elseif (findstr('neareset_pose', sim_results.method{i}) > 0)
            index_set = [index_set i];
        elseif (findstr('max_corr', sim_results.method{i}) > 0)
            index_set = [index_set i];
        elseif (findstr('procrustes', sim_results.method{i}) > 0)
            index_set = [index_set i];
        elseif (findstr('sum_projection', sim_results.method{i}) > 0)
            index_set = [index_set i];
        end
    end;
    
    % create results struct
    res.name = 'No sqrt for MBGS, pose base, basic, max_corr, projection, procrustes';
    res.method = create_method(sim_results, index_set);
    [res.avg, res.se] = get_svm_results(sim_results, index_set);     
    composite_results{exmpale_number} = res;    
    exmpale_number = exmpale_number + 1;

% ans = 
% 
%       name: 'No sqrt for MBGS, pose base, basic, max_corr, projection, procrustes'
%     method: {1x54 cell}
%        avg: 0.7768
%         se: 0.0198
    
   % Example 8:
    fprintf('[%s]: 8. All results\n', datestr(now));

    % create index set
    index_set = [1:sz];

    % create results struct
    res.name = 'All results';
    res.method = create_method(sim_results, index_set);
    [res.avg, res.se] = get_svm_results(sim_results, index_set);
    composite_results{exmpale_number} = res;
    exmpale_number = exmpale_number + 1;



    % Example 9:
    fprintf('[%s]: 9. All LBP\n', datestr(now));

    % create index set
    index_set = [];
    for i = 1:sz
        if (sim_results.feat(i) == 3)
            index_set = [index_set i];
        end
    end;

    % create results struct
    res.name = 'All LBP';
    res.method = create_method(sim_results, index_set);
    [res.avg, res.se] = get_svm_results(sim_results, index_set);
    composite_results{exmpale_number} = res;
    exmpale_number = exmpale_number + 1;

end

% create the methods name, including the feature name and if it is sqrt
function method = create_method(sim_results, index_set)
    sz = size(index_set,2);
    for i = 1:sz
        ind = index_set(i);
        str = sprintf('%s_%s', sim_results.method{ind},...
                               sim_results.feat_name{sim_results.feat(ind)});
        if (sim_results.issqrt(i) == 1)
            str = sprintf('%s_sqrt', str);
        end
        method{i} = str;
    end
end


% get classification results by using SVM - 
% avg - the mean. 
% se - std
function [avg, se] = get_svm_results(sim_results, index_set)

    X = diag(sim_results.polarity(index_set)) * sim_results.similarity(index_set,:);
    y = sim_results.y;
    splitid = sim_results.splitid;

    uniq_ids = unique(splitid);
    numsplits = length(uniq_ids);

    weights = zeros(size(X,2),1);
    classification_results = zeros(numsplits,1);
    
    % for each split the test set will be the current split's data, and the 
    % training set will be built from other 8 splits
    for split = 1:numsplits
      side_split = split + 1;
      if (side_split > numsplits)
        side_split = 1;
      end
      test_ids = find(splitid==uniq_ids(split));
      side_ids = find(splitid==uniq_ids(side_split));    
      train_ids = (setdiff(1:size(splitid,1), [test_ids ; side_ids]));
      
      Xtrain = X(:,train_ids);
      Xtest = X(:,test_ids);
      ytrain = y(train_ids);
      ytest = y(test_ids);

      model = CLSlibsvm(Xtrain, ytrain);
      [ry,rw] = CLSlibsvmC(Xtest, model);

      if sum(isnan(rw))
          fprintf('[%s]: using boosting instead of svm, split %d\n',...
                   datestr(now), split);
          sPARAMS.Nrounds = 1;
          model = CLSgentleBoost(Xtrain, ytrain, sPARAMS);
          [ry,rw] = CLSgentleBoostC(Xtest, model);
      end
      
      % the result for the current split is the number of correct labeling
      classification_results(split) = mean(ry == ytest);
      
    end
    
    avg = mean(classification_results);
    se = std(classification_results);

end
