function [features, motion_dim, params] = extract_all_features(...
                                            experiment_name, time_points,...
                                            frscale, ...
                                            marker, ...
                                            dim, ...
                                            params, tns_flag)
% 2-way feature extraction. Feature set includes time-delayed scalogramms
% for all electrodes and ECoG signals for all electrodes (time delay is the same)
% Resulting feature dimensions are [Nchannels x (Nfrequencies + 1)]
%
% Inputs:
% experiment_name - str with experiment ID, same as the corresponding folder 
%                   with experimental data
% time_points - list of time points; one point corresponds to ine object in 
%               the data sample 
% frscale - upsampling factor for ECoG data. Since scalogram frequency
%           range is bounded from above by fs/2, to increase range of
%           scales, x must be 'upsampled' (adds frscale points between each 
%           two entries in time_points when computing scalogram)
% marker - str, specifies marker for target variable (i.e 'lwr', 'rh' etc.)
% dim - list of integers from [1,2,3]. Corresponds to x,y,z dimensions
% params  - structure with parameters, returned by extract_max_corr_features.m 
%           !!! here only the field 'tdelay' is used + frequency_bands
% tns_flag - boolean, defines the data type
%
% Outputs:
% features - features matrix (2-way if tns_flag = 0, 3-way otherwise)
% motion_dim - target variables at specified time points for given motion 
%              markers and spatial dimensions
MARKER = 'wr';
params.modes = [0, 0];

if ~exist('params', 'var') || isempty(params)
    params = struct();
end
param_fields = fieldnames(params);

if ~exist('marker', 'var')
    marker = MARKER;
end

if ~exist('tns_flag', 'var')
    tns_flag = 0;
end

if ismember('dim', param_fields) && isempty(dim)
    dim = params.dim;
end

if ismember('marker', param_fields) && isempty(marker)
    marker = params.marker;
end

% select contralateral marker:
if strfind(experiment_name, '_A_')
    marker = ['l', marker];
else
    marker = ['r', marker];
end

file_prefix = strcat('../data/', experiment_name, '/');

D = importdata(strcat(file_prefix, 'Motion.csv'));
motion_time = D.data(:, 1);
motion_data = D.data(:, 2:end);
markers = D.colheaders(2:end);

% Extract only the relevant markers (exclude experimenter's hand:
mk_idx = cellfun(@(x) ~isempty(strfind(lower(x), marker)), markers, 'UniformOutput', 1);
not_exp_idx = cellfun(@(x) isempty(strfind(lower(x), 'exp')), markers, 'UniformOutput', 1);
motion_data = motion_data(:, mk_idx & not_exp_idx);

% Read ECoG data:
D = importdata(strcat(file_prefix, 'ECoG.csv')); % reloads variable 'data'
time = D.data(:, 1);
data = D.data(:, 2:end);
electrodes = D.colheaders(2:end);
params.nchannels = length(electrodes);

% 'upsample' x: increase frequency by factor of 5
time_points_hfr = linspace(time_points(1), time_points(end), ...
                                            length(time_points)*frscale);
idx_lfr = 1:frscale:length(time_points_hfr);

% TODO better use somesmoothing approximation
% To associate time ticks and time_points, use interpolation
disp('Interpolating motion data');
[y, ~] = oneD_gridded_interpolation(motion_data, motion_time, ...
                                                time_points, 1);

disp('Interpolating ECoG data');
[xhfr, ~] = oneD_gridded_interpolation(data, time, time_points_hfr, 1); 
x = xhfr(idx_lfr, :);
% [x, ~] = oneD_gridded_interpolation([], Fx, time_points, 1);

%--------------------------------------------------------------------------
% Look for correlations between channels and motion data in time domain:
motion_dim = y(:, dim);
td_electrodes = 1:length(electrodes);
td_idx = params.tdelay(1); mdl = params.tdelay(2);
nbest_td = length(td_electrodes);
params.modes(1) = nbest_td;

if tns_flag
    features = zeros(length(time_points) - td_idx, nbest_td);
    for f = 1:nbest_td
        features(:, f) = x(td_idx + 1:end, td_electrodes(f));
    end
else
    features = zeros(length(time_points) - td_idx, nbest_td);
    for f = 1:nbest_td
        features(:, f) = x(td_idx + 1:end, td_electrodes(f));
    end
end


%--------------------------------------------------------------------------  
fs = round(1/mean(diff(time_points_hfr)));   
frequency_bands = params.frequency_bands;
frequency_bands = frequency_bands(frequency_bands(:, 2) <= 0.5 * fs, :);                
fr_range = frequency_range(frequency_bands);
nfreqs = length(fr_range);
params.modes(2) = 1 + nfreqs;

scalos = scalos_by_electrodes(xhfr, frequency_bands, fs, 'none', ...
                                                    1:length(electrodes));

if tns_flag
    features = reshape(features, size(features, 1), size(features, 2), []);
    features(:, :, 2:1+nfreqs) = zeros(size(features, 1), size(features, 2), nfreqs);
    for f = 1:length(electrodes)
        scalo = scalos{f}(idx_lfr, :);
        if params.log
            scalo = log(scalo);
        end
        features(:, f, 2:1+nfreqs) = scalo(td_idx + 1:end, :);
    end
    
else
    for f = 1:length(electrodes)
        scalo = scalos{f}(idx_lfr, :);
        if params.log
            scalo = log(scalo);
        end
        features = [features, scalo(td_idx + 1:end, :)];
    end
    idx_feats = reshape_2D_matfeatures(1:size(features, 2), length(electrodes), nfreqs);
    idx_feats = idx_feats(:);
    features = features(:, idx_feats);
end

% adjust y's time points:
motion_dim = motion_dim(mdl:end-td_idx, :);


end

function xx = reshape_2D_matfeatures(x, nchan, nfreqs)
% This script reshapes x into nchan x (1 + nfreqs) matrix
% x is a [1x nchan(1 + nfreqs)] vec such that :
%   1--nchan entries correspond to time series;
%   nchan + (1--nfreqs)   correspond to scalograms along 1st channel
%   nchan + nfreqs + (1--nfreqs) correspond to scs along 2nd channel

xx = zeros(nchan, 1 + nfreqs);
xx(:, 1) = x(1:nchan);

for ch = 1:nchan
    xx(ch, 2:end) = x(nchan + (ch-1)*nfreqs + 1:nchan + ch*nfreqs);
end

end