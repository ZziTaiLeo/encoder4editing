% =========================================================================
%
% Analyze the results given in the sim_results and outputs them to a csv
% file.
% Prints the results to given output csv file in the following format:
% number, feature, method, issqrt, mean, std, AUC, EER
%
% Inputs:
% ~~~~~~
% sim_results - the similarity results structure as was calculated in 
%               calculate_all_similarities, i.e. loading the stored value 
%               or the return value of unify_similarity_matrix()
% output_csv_file - csv output file
% output_analyzed_file - the analyzed results output file where the 
%			 analyzed_results will be stored
% num_of_side_splits - number of side splits to use
%
% Outputs:
% ~~~~~~~
% analyzed_results - a matrix that contains the analyzed results. A single
%                    row for every similarity measure containing:
%                    [number, avg, se, roc_auc, roc_err]
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function analyzed_results = analyze_results(sim_results, output_csv_file,...
                                            output_analyzed_file, num_of_side_splits)   

    % X will represent the data with their polarity, so in all cases the
    % analysis will be the same: small = not same, big = same.
    % for example, in mindist the polarity is -1, so the smaller the
    % distance is the bigger is -distance which means same.
    %
    % every row in X has one similarity measure between all 5000 pairs
    X = diag(sim_results.polarity) * sim_results.similarity;
    
    analyzed_results = zeros(size(X,1), 5);
    num_similarties = size(X,1);
    for i = 1:num_similarties
        fprintf('[%s]: calculating similarity measure %d out of %d: %s, feat %s\n',...
                datestr(now), i, num_similarties, sim_results.method{i},...
                sim_results.feat_name{sim_results.feat(i)});        
        roc_stats = ROCetcmod(X(i,:)', sim_results.y, 0.001);
        current_X = double(X(i,:));
        [avg, se, weights] = get_svm_results(current_X, sim_results.y,...
                                             sim_results.splitid, num_of_side_splits);
        analyzed_results(i,:) = [i, avg, se, roc_stats.auc, roc_stats.errorateq];        
    end
    
    results_to_csv(analyzed_results, sim_results, output_csv_file);
    s.analyzed_results = analyzed_results;
    save(output_analyzed_file, '-struct', 's');
end

% get classification results by using SVM - 
% avg - the mean. 
% se - std
function [avg, se, weights] = get_svm_results(X, y, splitid, num_of_side_splits)

    uniq_ids = unique(splitid);
    numsplits = length(uniq_ids);

    weights = zeros(size(X,2),1);
    classification_results = zeros(numsplits,1);
    
    % for each split the test set will be the current split's data, and the 
    % training set will be built from other 8 splits
    % the side split is needed to be removed from the training, since it is
    % used as the background for MBGS and for LLC
    ignore_splitsize = 1;
    for split = 1:numsplits
      side_splits = get_side_split_indexes(split, numsplits, ignore_splitsize, num_of_side_splits);
      
      test_ids = find(splitid==uniq_ids(split));
      
      % create side_ids
      side_ids = [];
      for i=1:num_of_side_splits;
          side_ids = [side_ids ; find(splitid==uniq_ids(side_splits(i)))];
      end
      
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
      
      weights(test_ids) = rw;
      % the result for the current split is the number of correct labeling
      classification_results(split) = mean(ry == ytest);
      
    end
    
    avg = mean(classification_results);
    se = std(classification_results);

end

