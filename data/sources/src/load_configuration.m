% =========================================================================
%
% loads the configuration from the conf.txt file
%
% Inputs:
% ~~~~~~
% file - the configuration file name
%
% Outputs:
% ~~~~~~~
% the configuration struct is filled with the following information:
% classifiers - the location of the classifiers folder
% DB_root - the root of the DB with all the descriptors
% meta_data - meta data file with all the splits and labels
% headpose - the root of the head pose DB (the 3 head oriented vectors)
% results_dir - specify the location to store the results directory
% ROC_dir - the location of the ROC library
% pmk - the location of the pmk library
% llc - the location of the LLC library
% emgmm - the location of the emgmm library
% pmk_scratch - location of the pmk scratch to be used internally by the pmk
% methods - which methods to use to calculate similarity
% MBGS_params - MBGS parameters
%
% Copyright 2010, Lior Wolf, Tal Hassner, and Itay Maoz
%
% =========================================================================

function configuration = load_configuration(file)

    fid = fopen(file);
    while true
        tline = fgetl(fid);
        if (~ischar(tline)),   break,   end;  
        if (~isempty(tline))
            % remove and ignore spaces to avoid parsing problems
            tline = strrep(tline, ' ', '');
            
            % ignore comments
            comments = strfind(tline, '#');
            if (size(comments,2) > 0 && comments(1) == 1), continue, end;
            
            [key, remain] = strtok(tline,'=');
            [value] = strtok(remain,'=');
            if (strcmp(key, 'classifiers'))
                configuration.classifiers = value;
            end
            if (strcmp(key, 'DB_root'))
                configuration.DB_root = value;
            end
            if (strcmp(key, 'meta_data'))
                configuration.meta_data = value;
            end
            if (strcmp(key, 'headpose'))
                configuration.headpose = value;
            end
            if (strcmp(key, 'results_dir'))
                configuration.results_dir = value;
            end
            if (strcmp(key, 'ROC_dir'))
                configuration.ROC_dir = value;
            end
            if (strcmp(key, 'pmk'))
                configuration.pmk = value;
            end
            if (strcmp(key, 'llc'))
                configuration.llc = value;
            end
            if (strcmp(key, 'emgmm'))
                configuration.emgmm = value;
            end            
            if (strcmp(key, 'pmk_scratch'))
                configuration.pmk_scratch = value;
            end
            if (strcmp(key, 'methods'))
                configuration.methods = parse_methods(value);
            end
            if (strcmp(key, 'MBGS_type'))
                configuration.MBGS_params.type = str2num(value);
            end
            if (strcmp(key, 'MBGS_knn'))
                configuration.MBGS_params.knn = str2num(value);
            end
            if (strcmp(key, 'MBGS_bg_size'))
                configuration.MBGS_params.bg_size = str2num(value);
            end
            if (strcmp(key, 'MBGS_num_of_side_splits'))
                configuration.MBGS_params.num_of_side_splits = str2num(value);
            end            
        end
    end
end

function methods = parse_methods(methods_str)
    methods.basic = 0;
    methods.pose = 0;
    methods.algebraic = 0;
    methods.CMSM = 0;
    methods.PMK = 0;
    methods.LLC = 0;
    methods.MBGS = 0;
    methods.MBGS_sanity = 0;
    if (strcmp(methods_str, 'all'))
        methods.basic = 1;
        methods.pose = 1;
        methods.algebraic = 1;
        methods.CMSM = 1;
        methods.PMK = 1;
        methods.LLC = 1;
        methods.MBGS = 1;
        methods.MBGS_sanity = 1;
        return;
    end
        
    remain = methods_str;
    while true
        [str, remain] = strtok(remain, ',');
        if isempty(str),  break;  end
        if (strcmp(str,'basic'))
            methods.basic = 1;            
        end
        if (strcmp(str,'pose'))           
            methods.pose = 1;
        end
        if (strcmp(str,'algebraic'))
            methods.algebraic = 1;
        end
        if (strcmp(str,'CMSM'))
            methods.CMSM = 1;
        end
        if (strcmp(str,'PMK'))
            methods.PMK = 1;
        end
        if (strcmp(str,'LLC'))
            methods.LLC = 1;
        end
        if (strcmp(str,'MBGS'))
            methods.MBGS = 1;
        end
        if (strcmp(str,'MBGS_sanity'))
            methods.MBGS_sanity = 1;
        end
    end
end
