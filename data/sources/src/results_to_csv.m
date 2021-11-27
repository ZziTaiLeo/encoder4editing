% =========================================================================
%
% Prints results to the output csv file
%
% Inputs:
% ~~~~~~
% analyzed_results - the output of analyze_results()
% sim_results - the similarity results structure as was calculated by 
%               calculate_all_similarities() and unify_similarity_matrix()
% output_csv_file - csv output file
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================
function results_to_csv(analyzed_results, sim_results, output_csv_file)
    fid = fopen(output_csv_file,'w');
    
    fprintf(fid, 'number,feature,method,issqrt,mean,std,AUC,EER\n');
    %    measure_number mean std roc_auc roc_errorateq
    for i = 1:size(analyzed_results,1)
        fprintf(fid, '%d,%s,%s,%d,%f,%f,%f,%f\n',...
                i,...                
                sim_results.feat_name{sim_results.feat(i)},...
                sim_results.method{i},...
                sim_results.issqrt(i),...
                analyzed_results(i,2),...
                analyzed_results(i,3),...
                analyzed_results(i,4),...
                analyzed_results(i,5));
    end
    
    fclose(fid);
end