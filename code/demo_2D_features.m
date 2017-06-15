function demo_2D_features


addpath(fullfile(pwd, '..', '..', 'tensor_toolbox_2.6')); % your path to tensor toolbox
addpath(fullfile(pwd, 'utils'));
addpath(fullfile(pwd, 'qpfs'));
addpath(fullfile(pwd, 'data_preparation'));
addpath(fullfile(pwd, 'pls'));

% time points of interest:
TIME_STEP = 0.05;
time_points = 5:TIME_STEP:950;
step_str = strrep(num2str(TIME_STEP), '.', 'p');

MARKER = 'wr';
FRSCALE = 15; 
FEATURES = '2D'; 
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


% set parameters for 2D feature extraction:
params.tdelay = [0, 1]; % [td_idx, mdl]. td_idx >= mdl indicates positive delay
params.td_step = 0.05;
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
                                        
% Report results:
qpfs_feature_analysis(['saved data/QPFS_res', method, postfix, '.mat'], method);

end