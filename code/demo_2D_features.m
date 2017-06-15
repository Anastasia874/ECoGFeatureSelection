function demo_2D_features

% % Based on Makarchuk2016ECoGSignals/code
% addpath(fullfile(pwd,'..', '..', '..', 'Group374', 'Makarchuk2016ECoGSignals', 'code'));
addpath(fullfile(pwd, '..', '..', '..', '..', 'MATLAB', 'tensor_toolbox_2.6'));
addpath(fullfile(pwd, 'utils'));
addpath(fullfile(pwd, 'qpfs'));
addpath(fullfile(pwd, 'data_preparation'));

% time points of interest:
TIME_STEP = 0.05;
time_points = 5:TIME_STEP:950;
step_str = strrep(num2str(TIME_STEP), '.', 'p');

MARKER = 'wr';
FRSCALE = 15; 
FEATURES = '2D'; % '2D'
TNS_SIMILARITY = 'Tucker'; % could be 'Tucker' or 'unfold' for tns, 
MAT_SIMILARITY = 'correl'; % for matrices
dims = {'x', 'y', 'z'};
DIM = 1:3;
TNS_FLAG = 0;
LOG_FLAG = 1;
VEL = 0;

if TNS_FLAG
    folder = 'tns_mfe/';
    similarity = TNS_SIMILARITY;
else
    folder = 'manual_feat_extraction/';
    similarity = MAT_SIMILARITY;
end

experiment_name = '20090525S1_FTT_K1_ZenasChao_csv_ECoG64-Motion8';
date1 = experiment_name(1:10);



% % file with parameters for 2D feature extraction:
% % params_name = 'saved data/td_fd_feature_extraction_params_A_0p05_lwrz.mat';
% % load(params_name);
% set parameters for 2D feature extraction:
params.tdelay = [0, 1]; % [td_idx, mdl]. td_idx >= mdl indicates positive delay
params.td_step = 0.05;
% params.frequency_bands = [0.5, 3.5, 0.5; 4, 8, 0.5; ...
%                             9, 18, 3; 25, 50, 5; ...
%                             100, 500, 100; ];
params.frequency_bands = [10, 50, 10; 
                          60, 150, 10;];
assert(TIME_STEP == params.td_step);
delay = (params.tdelay(1) + 1 - params.tdelay(2))*TIME_STEP;
params.msdelay = delay;
featstr = [FEATURES, '_', strrep(num2str(delay), '.', 'p')];
featstr = strrep(featstr, '-', 'min');
if LOG_FLAG
    featstr = [featstr, '_log'];
end
if VEL
    featstr = [featstr, 'vel'];
end

params.features = FEATURES;
params.vel = VEL;
params.log = LOG_FLAG;


fprintf('Reading features (%s) for subject %s \n', FEATURES, experiment_name);
tic
% % N_BEST_TD = 15;
% % N_BEST_FD = 50;
% % [features1, motion_dim1, params] = extract_max_corr_features(...
% %                                             experiment_name, time_points,...
% %                                             MARKER, N_BEST_TD, N_BEST_FD, ...
% %                                             DIM, []);
% % save(params_name, 'params');
% 
% % [features1, motion_dim1, params] = extract_max_corr_features(...
% %                                             experiment_name, time_points,...
% %                                             [], [], [], [], params);
fprintf('Extracting delayed features with time delay = %0.2f s \n', delay);
[features1, motion_dim1, params] = extract_all_features(...
                                            experiment_name, time_points,...
                                            FRSCALE, MARKER, ...
                                            DIM, params, TNS_FLAG);
toc
%--------------------------------------------------------------------------
% Components for partial least squares for testing.
nfeats = size(reshape(features1, size(features1, 1), []), 2);
ncomp_to_try = [1, 5, 10, 30, 50:50:(nfeats-1), nfeats];
t_obs = 645; % ??
N_FOLDS = 5;
num_obs = sum(time_points <= t_obs);
% cvp = tspartition(num_obs, N_FOLDS); 

X_train = features1(1:num_obs, :, :, :); Y_train = motion_dim1(1:num_obs, :);
X_hold_out = features1(num_obs + 1:end, :, :, :);
Y_hold_out = motion_dim1(num_obs + 1:end, :);
if VEL                                           
Y_train(2:end, :) = Y_train(2:end, :) - Y_train(1:end-1, :);                                    
Y_hold_out(2:end, :) = Y_hold_out(2:end, :) - Y_hold_out(1:end-1, :);
% motion_dim2(2:end, :) = motion_dim2(2:end, :) - motion_dim2(1:end-1, :);
end

postfix = ['_', MARKER, strjoin(dims(DIM), ''), '_',  step_str, ...
            '_frscale_', num2str(FRSCALE), ...
            '_nfolds_', num2str(N_FOLDS),...
            '_', experiment_name(16:end)];

%--------------------------------------------------------------------------
% Katrutsa's QP feature selection:
qpfs = {};
qpfs.iters = 1;
qpfs.rank = 251;
qpfs.Arank = 1;
qpfs.sim = similarity;
qpfs.rel = 'correl';
qpfs.tns_flag = TNS_FLAG;
qpfs.ntries = 3;
qpfs.init = [];
qpfs.ff = 0.8; % forgetting factor for batch QPFS
qpfs.Qb = {[], []};
[err, ~, ~, idx_selected, pars, pvals, ak] = QP_feature_selection(...
                                        X_train, Y_train, N_FOLDS, qpfs, ...
                                                {X_hold_out}, ...
                                                {Y_hold_out});
                                            
tns_method = [TNS_SIMILARITY, '_', num2str(qpfs.iters), '_', num2str(qpfs.Arank)];
methods = {MAT_SIMILARITY, tns_method};
method = [featstr, '_', methods{TNS_FLAG + 1}];
res_fname = ['saved data/QPFS_res', method, postfix, '.mat'];
% err = recompute_errors(res_fname, X_train, Y_train, {X_hold_out, features2}, ...
%                                                  {Y_hold_out, motion_dim2});

% save(['saved data/QPFS_errors', method, postfix, '.mat'], 'err');
save(res_fname, 'err', 'idx_selected', 'pars', 'pvals', 'ak', 'qpfs', 'params');
                        
% load(['saved data/QPFS_errors', method, postfix, '.mat']);
[qp_mse, qp_crr, ~, qp_mse_train, qp_crr_train, ~, qp_crr_ho] = read_errors(err);


plot_cv_results_area2_nan({qp_crr_train, qp_crr, qp_crr_ho{1}}, ...
                      1:nfeats, 'Correlation coef', 'Number of features', ...
                       {[date1, ' train (cv)'], [date1, ' test (cv)'], ...
                       [date1, ' holdout']}, ...
                       [folder, 'corr_ho_QPFS_nfeats', method, postfix], ...
                       '-', 'none');
plot_cv_results_area2_nan({qp_mse_train, qp_mse}, ...
                      1:nfeats, 'Scaled MSE', 'Number of features', ...
                       {[date1, ' train (cv)'], [date1, ' test (cv)']}, ...
                       [folder, 'mse_QPFS_nfeats', method, postfix], ...
                       '-', 'none');                   
% Compare matrix to tensor implementation
compare_methods(featstr, methods, postfix, date1, [], 'qpfs_tns_to_matrix/', ...
                                        {'M', 'T'});
%                                         {'$\tau = 0$', '$\tau=0.65$'});
                                        
% Report results:
qpfs_feature_analysis(['saved data/QPFS_res', method, postfix, '.mat'], method);
%                    
%--------------------------------------------------------------------------
% PLS or other embedded feature selection
fs_time = tic;
lambda_range = [logspace(-10, -5, 10), logspace(-1, -0.5, 10)];

% err = lr_fun_crossval(X_train, Y_train, {X_hold_out, features2}, ...
%                                     {Y_hold_out, motion_dim2}, ...
%                                     N_FOLDS, lambda_range, ...
%                                     struct('learner', 'svm', 'reg_type', 'lasso'));


some_range = ncomp_to_try; %lambda_range;
pls_err = num2cell(zeros(N_FOLDS, length(some_range)));
for i = 1:length(some_range)
    fprintf('Iteration = %d / %d (ncomp = %d) \n', i, length(some_range), ...
        some_range(i));
    pls_fun = @(x_train, y_train, x_test, y_test)pls_fun_crossval(ncomp_to_try(i),...
                                        x_train, y_train, x_test, y_test, ...
                                        {X_hold_out, features2}, ...
                                        {Y_hold_out, motion_dim2}, 0);


    errors = crossval(pls_fun, X_train, Y_train, 'kfold', N_FOLDS);
    pls_err(:, i) = arrayfun(@(c) {c}, errors);                                        
end
toc(fs_time);

save(['saved data/PLS_errors', postfix, '.mat'], 'pls_err');
% load(['saved data/PLS_errors', postfix, '.mat']);
[mse, crr, dtwd, mse_train, crr_train, dtwd_train, crr_ho] = read_errors(pls_err);


plot_cv_results_area2({nanmean(crr_train), nanmean(crr), nanmean(crr_ho{1}), ...
                        nanmean(crr_ho{2})}, ...
                      {nanstd(crr_train), nanstd(crr), nanstd(crr_ho{1}), ...
                        nanstd(crr_ho{2})}, ...
                       some_range, 'Correlation coef', 'Number of features', ...
                       {[date1, ' train (cv)'], [date1, ' test (cv)'], ...
                       [date1, ' holdout'], date2}, ...
                       [folder, 'corr_PLS_ncomps_log_mat', postfix], ...
                       '-', 'none');

pls_crr_train = ones(size(qp_crr_train)) * nan;  
pls_crr_train(:, ncomp_to_try) = crr_train;
pls_crr = ones(size(qp_crr)) * nan;  
pls_crr(:, ncomp_to_try) = crr;
pls_crr_ho = ones(size(qp_crr_ho{2})) * nan;    
pls_crr_ho(:, ncomp_to_try) = crr_ho{2};
 
 plot_cv_results_area2_nan({pls_crr_train, pls_crr_ho, qp_crr_train, qp_crr_ho{2}}, ...
                        1:nfeats, 'Correlation coef', 'Number of features', ...
                       {[date1, ' PLS, train (cv)'], [date2, ' PLS'], ...
                       [date1, ' QP, train (cv)'], [date2, ' QP']}, ...
                       [folder, 'corr_ho_PLS_QP_nfeat', postfix], ...
                       '-', 'none');
                   
 plot_cv_results_area2_nan({pls_crr_train, pls_crr, qp_crr_train, qp_crr}, ...
                        1:nfeats, 'Correlation coef', 'Number of features', ...
                       {[date1, ' PLS, train (cv)'], [date1, ' PLS, test (cv)'], ...
                       [date1, ' QP, train (cv)'], [date1, ' QP, test (cv)']}, ...
                       [folder, 'corr_PLS_QP_nfeat', postfix], ...
                       '-', 'none');

% plot_cv_results_area2({mean(crr_train), mean(crr), mean(crr_ho{1}), mean(crr_ho{2})}, ...
%                       {std(crr_train), std(crr), std(crr_ho{1}), std(crr_ho{2})}, ...
%                        some_range, 'Correlation coef', ...
%                        {'train (cv)', 'test (cv)', 'holdout', 'later'})

end