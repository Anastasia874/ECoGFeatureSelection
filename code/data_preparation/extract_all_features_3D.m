function [features, motion_dim, params] = extract_all_features_3D(...
                                            experiment_name, time_points,...
                                            marker, ...
                                            dim, ...
                                            params, tns_flag)
% 3-way feature extraction. Basically, a simpler version of read_ecog_data.m
%
% Inputs:
% experiment_name - str with experiment ID, same as the corresponding folder 
%                   with experimental data
% time_points - list of time points; one point corresponds to ine object in 
%               the data sample 
% marker - str, specifies marker for target variable (i.e 'lwr', 'rh' etc.)
% dim - list of integers from [1,2,3]. Corresponds to x,y,z dimensions
% params  - structure with parameters of scalogram feature extration 
% tns_flag - boolean, defines the data type
%
% Outputs:
% features - features matrix (2-way if tns_flag = 0, 3-way otherwise)
% motion_dim - target variables at specified time points for given motion 
%              markers and spatial dimensions

MARKER = 'lwr';

if ~exist('marker', 'var')
    marker = MARKER;
end

if ~exist('params', 'var')
    params = [];
end

if isempty(params)
    params.time_interval = 1.0;
    params.time_edge = 0.1;  % in seconds
    params.ntimebins = 100;
    params.ds_rate = 1;  % no downsampling
    params.alpha = 'none'; % no artifacts removal
    params.frequency_bands = [1.5, 3.5, 1; 4, 8, 0.5; 8, 14, 1; ...
                                14, 20, 1; 20, 30, 1; 30, 50, 1; ...
                                50, 90, 2; 90, 100, 1; ];
end

time_interval = params.time_interval;
time_edge = params.time_edge;
ds_rate = params.ds_rate;
alpha = params.alpha;
ntimebins = params.ntimebins;
frequency_bands = params.frequency_bands;
file_prefix = ['../data/', experiment_name, '/'];

[features, ~, time_points] = read_and_save_X(file_prefix, time_points, time_edge, ...
                         time_interval, ntimebins, ...
                         frequency_bands, [], ds_rate, alpha, tns_flag);
                                
                                
D = importdata(strcat(file_prefix, 'Motion.csv'));
motion_time = D.data(:, 1);
motion_data = D.data(:, 2:end);
markers = D.colheaders(2:end);
% Extract only the relevant markers (exclude experimenter's hand:
mk_idx = cellfun(@(x) ~isempty(strfind(lower(x), marker)), markers, 'UniformOutput', 1);
exp_idx = cellfun(@(x) isempty(strfind(lower(x), 'exp')), markers, 'UniformOutput', 1);
motion_data = motion_data(:, mk_idx & exp_idx);

disp('Interpolating motion data');
[y, ~] = oneD_gridded_interpolation(motion_data, motion_time, time_points, 1);
motion_dim = y(:, dim);



end