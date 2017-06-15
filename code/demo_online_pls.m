function demo_online_pls


% Based on Makarchuk2016ECoGSignals/code
addpath(fullfile(pwd,'..', '..', '..', 'Group374', 'Makarchuk2016ECoGSignals', 'code'));
addpath(fullfile(pwd, '..', '..', '..', '..', 'MATLAB', 'tensor_toolbox_2.6'));
addpath(fullfile(pwd, 'utils'));
%--------------------------------------------------------------------------
% Read data:
motion_markers = 1:11; % 3:5 for right shoulder, elbow and wrist % (1:11); % All motion data. 

TIME_STEP = 0.005;
step_str = strrep(num2str(TIME_STEP), '.', 'p');

% data from http://neurotycho.org/download (Motion task, epidural)
% experiment_name = '20081127S1_FTT_A_ZenasChao_csv_ECoG32-Motion8';
experiment_name = '20090121S1_FTT_A_ZenasChao_csv_ECoG32-Motion10';
n_markers = strsplit(experiment_name, 'Motion');
n_markers = str2double(n_markers(end));
file_prefix = strcat('../data/', experiment_name, '/');

path_to_saved_data = 'D:/Users/motrenko/Projects/ecog/saved_data/';

file_out_X = [path_to_saved_data, experiment_name, '_X_', step_str, '.mat']; 
file_out_Y = [path_to_saved_data, experiment_name, '_Y_', step_str, '.mat'];

time_points = 5:TIME_STEP:950; % In experiment they have (5:0.005:950)

train_obs = 945;
train_time = time_points(time_points < train_obs);
test_time = time_points(time_points >= train_obs);

block_size = 500;
nsamples = length(train_time);
nblocks = ceil(nsamples / block_size);
mse = cell(1, nblocks);

Xblock = []; T = 50; W = []; beta_ = [];
forgetting_factor = 0.9;
regfuns = cell(1, nblocks);

train_errors = zeros(1, nblocks);
[Xtest, ytest] = read_ecog_data(file_prefix, test_time, 'RW', ...
                                [], [], 0);    
test_errors = zeros(1, nblocks);
moving_std = ones(1, size(ytest, 2));
moving_mean = zeros(1, size(ytest, 2));

for nb = [1, 5:nblocks]
    idx1 = block_size * (nb - 1) + 1; 
    idx2 = min(block_size*nb, nsamples);
    nb_time_points = train_time(idx1:idx2);
%     file_out_X = [path_to_saved_data, experiment_name, '_X_', step_str, ...
%                   '_block_', num2str(nb), '.mat']; 
%     file_out_Y = [path_to_saved_data, experiment_name, '_Y_', step_str, ...
%                   '_block_', num2str(nb), '.mat'];
   [Xnext, ynext] = read_ecog_data(file_prefix, nb_time_points, 'RW', ...
                                  [], [], 0);    
%     moving_std = moving_std * (1 - forgetting_factor) + ...
%                  std(ynext) * forgetting_factor;
%     moving_mean = moving_mean * (1 - forgetting_factor) + ...
%                   mean(ynext) * forgetting_factor;
%     ynext = demean(ynext, moving_mean, moving_std);
   [regfuns{nb}, T, W, beta_, mse{nb}, Xblock] = online_rnpls(Xblock, T, W, ...
                                                    beta_, Xnext, ynext, ...
                                                   forgetting_factor);   
    y_pred = regfuns{nb}(Xnext);
    train_errors(nb) = correlation_error(y_pred, ynext);
    y_pred = regfuns{nb}(Xtest);
    test_errors(nb) = correlation_error(y_pred, ytest);
    fprintf('nblock %d, train error %0.3f; test error %0.3f \n', nb, ...
                        train_errors(nb), test_errors(nb));
end

% mse contains norms of X (1st row) and y (2nd row) before and after reconstruction
mse = cat(3, mse{:}); % [2 x 2 x nblocks] matrix


%train_errors = zeros(1, nblocks);
% Convergence evaluation:
for nb = 1:nblocks
    y_pred = regfuns{nb}(Xtest);
    test_errors(nb) = correlation_error(y_pred, ytest);
end



end


function X = demean(X, mx, ms)

X = X - repmat(mx, size(X, 1), 1);
X = X ./ repmat(ms, size(X, 1), 1);

end