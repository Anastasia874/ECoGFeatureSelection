function demo_3D_features_online

% % Based on Makarchuk2016ECoGSignals/code
addpath(fullfile(pwd,'..', '..', '..', 'Group374', 'Makarchuk2016ECoGSignals', 'code'));
addpath(fullfile(pwd, '..', '..', '..', '..', 'MATLAB', 'tensor_toolbox_2.6'));
addpath(fullfile(pwd, 'utils'));
addpath(fullfile(pwd, 'qpfs'));
addpath(fullfile(pwd, 'data_preparation'));

% time points of interest:
TIME_STEP = 0.05;
time_points = 5:TIME_STEP:950; % !!! 950
step_str = strrep(num2str(TIME_STEP), '.', 'p');

MARKER = 'lwr';
FRSCALE = 15; 
FEATURES = '3D';
TNS_SIMILARITY = 'Tucker'; % could be 'Tucker' or 'unfold' for tns, 
MAT_SIMILARITY = 'correl'; % for matrices
dims = {'x', 'y', 'z'};
DIM = 1:3;
TNS_FLAG = 1;
VEL = 0;

if TNS_FLAG
    folder = 'tns_mfe/';
    similarity = TNS_SIMILARITY;
else
    folder = 'manual_feat_extraction/';
    similarity = MAT_SIMILARITY;
end

experiment_name = '20090121S1_FTT_A_ZenasChao_csv_ECoG32-Motion10';
date1 = experiment_name(1:10);

% set parameters for 3D feature extraction:
params.time_interval = 1.0;
params.time_edge = 0.1;  % in seconds
params.ntimebins = 10;  % !!! 20
params.ds_rate = 1;  % no downsampling
params.alpha = 'none'; % no artifacts removal
params.frscale = FRSCALE;
params.sample_fr = 1/TIME_STEP;
 % !!! 
% params.frequency_bands = [0.5, 3.5, 0.5; 4, 8, 0.5; ...
%                             9, 18, 3; 25, 50, 5; ...
%                             100, 500, 100; ];
params.frequency_bands = [10, 50, 10; ...
                            60, 150, 10; ];

featstr = FEATURES;
if LOG_FLAG
    featstr = [featstr, '_log'];
end
if VEL
    featstr = [featstr, 'vel'];
end
params.features = FEATURES;

t_obs = 650; % !!! 650
num_obs = sum(time_points <= t_obs);
time_points_train = time_points(1:num_obs);
time_points_test = time_points(1 + num_obs:end);

[sizes1, sizes2] = estimate_dataset_size(time_points_train, params, TNS_FLAG);
params.modes = [params.ntimebins, sizes1(2:end)];
nfeats = prod(sizes2(2:end));
MAX_RAW_TIMEPOINTS = 200000;
nbatches = ceil(sizes1(1) / MAX_RAW_TIMEPOINTS);
time_idx = round(linspace(time_points_train(1) - TIME_STEP, ...
                                    time_points_train(end), nbatches + 1));

% Katrutsa's QP feature selection:
qpfs = {};
qpfs.iters = 1;
qpfs.rank = 251;
qpfs.Arank = 1;
qpfs.sim = similarity;
qpfs.rel = 'correl';
qpfs.tns_flag = TNS_FLAG;
qpfs.init = [];
qpfs.ntries = 1; % max number of failed attempts to solve opt. problem
qpfs.ff = 0.8; % forgetting factor for batch QPFS
qpfs.Qb = {[], []};
N_FOLDS = 3;
tic
fprintf('Reading hold-out features (%s) for subject %s \n', FEATURES, experiment_name);
[X_hold_out, Y_hold_out, params] = extract_all_features_3D(...
                                            experiment_name, time_points_test,...
                                            MARKER, DIM, ...
                                            params, TNS_FLAG);
if VEL                                        
X_hold_out(2:end, :, :, :) = X_hold_out(2:end, :, :, :) - X_hold_out(1:end-1, :, :, :);                                     
Y_hold_out(2:end, :) = Y_hold_out(2:end, :) - Y_hold_out(1:end-1, :);
end
toc
err = cell(1, nbatches);
%--------------------------------------------------------------------------
for nb = 1:nbatches
time_points_nb = time_idx(nb) + TIME_STEP:TIME_STEP:time_idx(nb + 1);
tnb = tic;
fprintf('Reading features (%s) for batch %i / %i \n', FEATURES, nb, nbatches);
[X_train, Y_train, params] = extract_all_features_3D(...
                                            experiment_name, time_points_nb,...
                                            MARKER, DIM, ...
                                            params, TNS_FLAG);   
if VEL                                        
    X_train(2:end, :, :, :) = X_train(2:end, :, :, :) - X_train(1:end-1, :, :, :);                                     
    Y_train(2:end, :) = Y_train(2:end, :) - Y_train(1:end-1, :);
end
toc(tnb);
[err{nb}, ~, ~, idx_selected{nb}, pars{nb}, pvals{nb}, ak{nb}, Qb] = QP_feature_selection(...
                                        X_train, Y_train, N_FOLDS, qpfs, ...
                                         {X_hold_out}, {Y_hold_out});
qpfs.init = ak{nb}{end};
qpfs.Qb = Qb;

end
%--------------------------------------------------------------------------



postfix = ['_', MARKER, strjoin(dims(DIM), ''), '_',  step_str, ...
            '_frscale_', num2str(FRSCALE), ...
            '_nfolds_', num2str(N_FOLDS),...
            '_', experiment_name(16:end)];
                                            
tns_method = [TNS_SIMILARITY, '_', num2str(qpfs.iters), '_', num2str(qpfs.Arank)];
methods = {MAT_SIMILARITY, tns_method};
method = [featstr, '_', methods{TNS_FLAG + 1}];
res_fname = ['saved data/QPFS_res', method, postfix, '.mat'];
% err = recompute_errors(res_fname, X_train, Y_train, {X_hold_out, features2}, ...
%                                                  {Y_hold_out, motion_dim2});

% save(['saved data/QPFS_errors', method, postfix, '.mat'], 'err');
save(res_fname, 'err', 'A', 'complexity', 'idx_selected', 'pars', 'pvals', 'qpfs', 'params');
                        
% load(['saved data/QPFS_errors', method, postfix, '.mat']);
[qp_mse, qp_crr, ~, qp_mse_train, qp_crr_train, ~, qp_crr_ho] = read_errors(err);


plot_cv_results_area2_nan({qp_crr_train, qp_crr, qp_crr_ho{1}, qp_crr_ho{2}}, ...
                      1:nfeats, 'Correlation coef', 'Number of features', ...
                       {[date1, ' train (cv)'], [date1, ' test (cv)'], ...
                       [date1, ' holdout'], date2}, ...
                       [folder, 'corr_ho_QPFS_nfeats', method, postfix], ...
                       '-', 'none');
plot_cv_results_area2_nan({qp_mse_train, qp_mse}, ...
                      1:nfeats, 'Scaled MSE', 'Number of features', ...
                       {[date1, ' train (cv)'], [date1, ' test (cv)']}, ...
                       [folder, 'mse_QPFS_nfeats', method, postfix], ...
                       '-', 'none');                   
% Compare matrix to tensor implementation
compare_methods(featstr, methods, postfix, date1, date2, 'qpfs_tns_to_matrix/', ...
                                        {'M', 'T'});
%                                         {'$\tau = 0$', '$\tau=0.65$'});
                                        
% Report results:
qpfs_feature_analysis(['saved data/QPFS_res', method, postfix, '.mat'], method);
                   
end