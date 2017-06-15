function demo_prediction_across_subjects_3D

addpath(fullfile(pwd, '..', '..', 'tensor_toolbox_2.6'));  % your path to tensor toolbox
addpath(fullfile(pwd, 'utils'));
addpath(fullfile(pwd, 'qpfs'));
addpath(fullfile(pwd, 'data_preparation'));
addpath(fullfile(pwd, 'pls'));

% time points of interest:
TIME_STEP = 0.05;
time_points = 5:TIME_STEP:950;
step_str = strrep(num2str(TIME_STEP), '.', 'p');

MARKER = 'wr'; % wrist, left for monkey A, right for monkey K
FRSCALE = 15; 
FEATURES = '3D';
TNS_SIMILARITY = 'Tucker'; % could be 'Tucker' or 'unfold' for tns, 
MAT_SIMILARITY = 'correl'; % for matrices
dims = {'x', 'y', 'z'};
DIM = 1:3;
LOG_FLAG = 0;
VEL = 0;  % true for predicting differenced time series


experiments = {'20090602S1_FTT_K1_ZenasChao_csv_ECoG64-Motion7', ...
               '20090525S1_FTT_K1_ZenasChao_csv_ECoG64-Motion8', ...
               '20090527S1_FTT_K1_ZenasChao_csv_ECoG64-Motion8', ...
               '20081127S1_FTT_A_ZenasChao_csv_ECoG32-Motion8',...
               '20090116S1_FTT_A_ZenasChao_csv_ECoG32-Motion10', ...
               '20081224S1_FTT_A_ZenasChao_csv_ECoG32-Motion10', ...
               '20090121S1_FTT_A_ZenasChao_csv_ECoG32-Motion10', ...
               '20090611S1_FTT_A_ZenasChao_csv_ECoG32-Motion12'}; 
           
           

% set parameters for 3D feature extraction:
params.time_interval = 1.0;
params.time_edge = 0.1;  % in seconds
params.ntimebins = 10;  %
params.ds_rate = 1;  % no downsampling
params.alpha = 'none'; % no artifacts removal
params.frscale = FRSCALE;
params.sample_fr = 1/TIME_STEP;
params.frequency_bands = [10, 50, 10; 
                          60, 150, 10;];


featstr = FEATURES;
if LOG_FLAG
    featstr = [featstr, '_log'];
end
if VEL
    featstr = [featstr, 'vel'];
end

params.features = FEATURES;
params.vel = VEL;
params.log = LOG_FLAG;
%--------------------------------------------------------------------------
% Katrutsa's QP feature selection:
qpfs = {};
qpfs.iters = 1;
qpfs.rank = 251;
qpfs.Arank = 1;
qpfs.rel = 'correl';
qpfs.ntries = 3;
qpfs.ff = 0.8; % forgetting factor for batch QPFS
qpfs.Qb = {[], []};
qpfs1 = qpfs; qpfs0 = qpfs;
qpfs1.tns_flag = 1; qpfs0.tns_flag = 0;
qpfs1.sim = TNS_SIMILARITY;
qpfs0.sim = MAT_SIMILARITY;
%--------------------------------------------------------------------------
% Components for partial least squares for testing.
ncomp_to_try = [10, 25, 50, 100, 200, 500];
t_obs = 645; % ??
N_FOLDS = 5;
% cvp = tspartition(num_obs, N_FOLDS); 

tns_method = [TNS_SIMILARITY, '_', num2str(qpfs.iters), '_', num2str(qpfs.Arank)];
methods = [MAT_SIMILARITY, '_', tns_method];
method = [featstr, '_', methods];
postfix = ['_', MARKER, strjoin(dims(DIM), ''), '_',  step_str, ...
            '_frscale_', num2str(FRSCALE), ...
            '_nfolds_', num2str(N_FOLDS)];
res_fname = ['saved data/subjects_res', method, postfix, '.mat'];


num_obs = sum(time_points <= t_obs);
time_points_train = time_points(1:num_obs);
time_points_test = time_points(1 + num_obs:end);

sizes1 = estimate_dataset_size(time_points_train, params, 1);
params.modes = [params.ntimebins, sizes1(2:end)];

MAX_RAW_TIMEPOINTS = 200000;
nbatches = ceil(sizes1(1) / MAX_RAW_TIMEPOINTS);
time_idx = round(linspace(time_points_train(1) - TIME_STEP, ...
                                    time_points_train(end), nbatches + 1));
tns_err = cell(numel(experiments), nbatches); mat_err = tns_err;
tns_pls_err = tns_err; mat_pls_err = tns_err;        
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------        
for nexp = 1:numel(experiments)
    
experiment_name = experiments{nexp};
qpfs1.init = []; qpfs0.init = [];  
fprintf('Reading hold-out features (%s) for subject %s \n', FEATURES, experiment_name);
[X_hold_out, Y_hold_out, params] = extract_all_features_3D(...
                                            experiment_name, time_points_test,...
                                            MARKER, DIM, ...
                                            params, 1);
if VEL                                        
X_hold_out(2:end, :, :, :) = X_hold_out(2:end, :, :, :) - X_hold_out(1:end-1, :, :, :);                                     
Y_hold_out(2:end, :) = Y_hold_out(2:end, :) - Y_hold_out(1:end-1, :);
end
qpfs0.Qb = {[], []}; qpfs1.Qb = {[], []};
%--------------------------------------------------------------------------
for nb = 1:nbatches  
    time_points_nb = time_idx(nb) + TIME_STEP:TIME_STEP:time_idx(nb + 1);
    tnb = tic;
    fprintf('Reading features (%s) for batch %i / %i, subject %s \n', ...
                            FEATURES, nb, nbatches, experiment_name);
    [X_train, Y_train, params] = extract_all_features_3D(...
                                                experiment_name, time_points_nb,...
                                                MARKER, DIM, ...
                                                params, 1);   
    if VEL                                        
        X_train(2:end, :, :, :) = X_train(2:end, :, :, :) - X_train(1:end-1, :, :, :);                                     
        Y_train(2:end, :) = Y_train(2:end, :) - Y_train(1:end-1, :);
    end
    toc(tnb);
%     % Tensor QPFS:
%     qpfst = tic;
%     [tns_err{nexp}{nb}, ~, ~, ~, ~, ~, ak, Qb] = QP_feature_selection(...
%                                             X_train, Y_train, N_FOLDS, qpfs1, ...
%                                              {X_hold_out}, {Y_hold_out}, ...
%                                              ncomp_to_try);
%     qpfs1.init = ak{end}; qpfs1.Qb = Qb;
%     fprintf('Tensor QPFS: %i iterations done \n', length(ncomp_to_try));
%     toc(qpfst); 
%     % Matrix QPFS:
%     qpfst = tic;
%     [mat_err{nexp}{nb}, ~, ~, ~, ~, ~, ak, Qb] = QP_feature_selection(...
%                                             X_train, Y_train, N_FOLDS, qpfs0, ...
%                                              {X_hold_out}, {Y_hold_out}, ...
%                                              ncomp_to_try);
%     qpfs0.init = ak{end}; qpfs0.Qb = Qb;
%     fprintf('Matrix QPFS: %i iterations done \n', length(ncomp_to_try));
%     toc(qpfst);                
%     %--------------------------------------------------------------------------
    % PLS or other embedded feature selection
    fs_time = tic;
    tns_pls_err{nexp}{nb} = num2cell(zeros(N_FOLDS, length(ncomp_to_try)));
    mat_pls_err{nexp}{nb} = num2cell(zeros(N_FOLDS, length(ncomp_to_try)));
    for i = 1:length(ncomp_to_try)
        fprintf('Iteration = %d / %d (ncomp = %d) \n', i, length(ncomp_to_try), ...
            ncomp_to_try(i));
        mat_pls_fun = @(x_train, y_train, x_test, y_test)pls_fun_crossval(ncomp_to_try(i),...
                                            x_train, y_train, x_test, y_test, ...
                                            {X_hold_out}, ...
                                            {Y_hold_out}, 0);
        tns_pls_fun = @(x_train, y_train, x_test, y_test)pls_fun_crossval(ncomp_to_try(i),...
                                            x_train, y_train, x_test, y_test, ...
                                            {X_hold_out}, ...
                                            {Y_hold_out}, 1);
%         errors = crossval(mat_pls_fun, X_train, Y_train, 'kfold', N_FOLDS);
%         mat_pls_err{nexp}{nb}(:, i) = arrayfun(@(c) {c}, errors);  
        errors = crossval(tns_pls_fun, X_train, Y_train, 'kfold', N_FOLDS);
        tns_pls_err{nexp}{nb}(:, i) = arrayfun(@(c) {c}, errors);                                        
    end
    fprintf('PLS: %i iterations done \n', length(ncomp_to_try));
    toc(fs_time);

end
save(res_fname, 'tns_err', 'mat_err', 'tns_pls_err', 'mat_pls_err', ...
                                    'experiments', 'ncomp_to_try');
end


% res_fname = ['saved data/subjects_res_tns_qpfs', method, postfix, '.mat'];
% save(res_fname, 'tns_err', 'mat_err', 'tns_pls_err', 'mat_pls_err', ...
%                                     'experiments', 'ncomp_to_try');


end