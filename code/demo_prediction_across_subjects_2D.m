function demo_prediction_across_subjects_2D

addpath(fullfile(pwd, '..', '..', 'tensor_toolbox_2.6'));  % your path to tensor toolbox
addpath(fullfile(pwd, 'utils'));
addpath(fullfile(pwd, 'qpfs'));
addpath(fullfile(pwd, 'data_preparation'));
addpath(fullfile(pwd, 'pls'));

% time points of interest:
TIME_STEP = 0.05;
time_points = 5:TIME_STEP:70;
step_str = strrep(num2str(TIME_STEP), '.', 'p');

MARKER = 'wr'; % wrist, left for monkey A, right for monkey K
FRSCALE = 15; 
FEATURES = '2D'; % '3D'
TNS_SIMILARITY = 'Tucker'; % could be 'Tucker' or 'unfold' for tns, 
MAT_SIMILARITY = 'correl'; % for matrices
dims = {'x', 'y', 'z'};
DIM = 1:3;
TNS_FLAG = 1;
LOG_FLAG = 0;
VEL = 0;  % true for predicting differenced time series

if TNS_FLAG
    folder = 'tns_mfe/';
    similarity = TNS_SIMILARITY;
else
    folder = 'manual_feat_extraction/';
    similarity = MAT_SIMILARITY;
end

experiments = {'20090116S1_FTT_A_ZenasChao_csv_ECoG32-Motion10', ...
               '20090525S1_FTT_K1_ZenasChao_csv_ECoG64-Motion8', ...
               '20090527S1_FTT_K1_ZenasChao_csv_ECoG64-Motion8', ...
               '20090602S1_FTT_K1_ZenasChao_csv_ECoG64-Motion7', ...
               '20081127S1_FTT_A_ZenasChao_csv_ECoG32-Motion8',...
               '20081224S1_FTT_A_ZenasChao_csv_ECoG32-Motion10', ...
               '20090121S1_FTT_A_ZenasChao_csv_ECoG32-Motion10', ...
               '20090611S1_FTT_A_ZenasChao_csv_ECoG32-Motion12'}; 
           
           

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
params.modes = [32, 15]; % !!!!

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
%--------------------------------------------------------------------------
% PLS and train-test parameters
ncomp_to_try = [10, 25, 50, 100, 200, 500];
t_obs = 45; % ??
N_FOLDS = 5;
num_obs = sum(time_points <= t_obs);
% cvp = tspartition(num_obs, N_FOLDS); 

tns_method = [TNS_SIMILARITY, '_', num2str(qpfs.iters), '_', num2str(qpfs.Arank)];
methods = {MAT_SIMILARITY, tns_method};
method = [featstr, '_', methods{TNS_FLAG + 1}];
postfix = ['_', MARKER, strjoin(dims(DIM), ''), '_',  step_str, ...
            '_frscale_', num2str(FRSCALE), ...
            '_nfolds_', num2str(N_FOLDS)];
        
for nexp = 1:numel(experiments)
    
experiment_name = experiments{nexp};    
fprintf('Reading features (%s) for subject %s \n', FEATURES, experiment_name);
tic
fprintf('Extracting delayed features with time delay = %0.2f s \n', delay);
[features1, motion_dim1, params] = extract_all_features(...
                                            experiment_name, time_points,...
                                            FRSCALE, MARKER, ...
                                            DIM, params, TNS_FLAG);
toc


X_train = features1(1:num_obs, :, :, :); Y_train = motion_dim1(1:num_obs, :);
X_hold_out = features1(num_obs + 1:end, :, :, :);
Y_hold_out = motion_dim1(num_obs + 1:end, :);
if VEL                                           
Y_train(2:end, :) = Y_train(2:end, :) - Y_train(1:end-1, :);                                    
Y_hold_out(2:end, :) = Y_hold_out(2:end, :) - Y_hold_out(1:end-1, :);
end

qpfs.tns_flag = 0;
qpfst = tic;
mat_err{nexp} = QP_feature_selection(X_train, Y_train, N_FOLDS, qpfs, ...
                                                {X_hold_out}, ...
                                                {Y_hold_out}, ...
                                                ncomp_to_try); 
fprintf('Matrix QPFS: %i iterations done', length(ncomp_to_try));
toc(qpfst);
qpfs.tns_flag = 1;
qpfst = tic;
tns_err{nexp} = QP_feature_selection(X_train, Y_train, N_FOLDS, qpfs, ...
                                                {X_hold_out}, ...
                                                {Y_hold_out}, ...
                                                ncomp_to_try);
fprintf('Tensor QPFS: %i iterations done', length(ncomp_to_try));
toc(qpfst);                 
%--------------------------------------------------------------------------
% % PLS or other embedded feature selection
fs_time = tic;
tns_pls_err{nexp} = num2cell(zeros(N_FOLDS, length(ncomp_to_try)));
mat_pls_err{nexp} = num2cell(zeros(N_FOLDS, length(ncomp_to_try)));
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
    errors = crossval(mat_pls_fun, X_train, Y_train, 'kfold', N_FOLDS);
    mat_pls_err{nexp}(:, i) = arrayfun(@(c) {c}, errors);  
    errors = crossval(tns_pls_fun, X_train, Y_train, 'kfold', N_FOLDS);
    tns_pls_err{nexp}(:, i) = arrayfun(@(c) {c}, errors);                                        
end
fprintf('PLS: %i iterations done', length(ncomp_to_try));
toc(fs_time);

end

res_fname = ['saved data/subjects_res', method, postfix, '.mat'];
save(res_fname, 'tns_err', 'mat_err', 'tns_pls_err', 'mat_pls_err', ...
                                    'experiments', 'ncomp_to_try', 'params');

 


end