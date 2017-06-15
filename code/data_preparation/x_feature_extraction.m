function [X_set, D] = x_feature_extraction(file_prefix, time_points, ...
                                    time_interval, time_edge, ...
                                    frequency_bands, file_out, ds_rate, ...
                                    alpha)

% Read ECoG millivoltage data in .csv format, make a feature matrix and
% save it .mat file
% Inputs:
% file_prefix - specifies which dataset to load (name of the experiment)
% time_ponits - vector of floats from 0 to 1000 (seconds); time range
% time_edge - specifies edge of the scalogramm that will be latter discarded 
% frequency_bands - [N_fb x 3] matrix, each row is a time band; first two
%           entries are the the lower and the upper bounds, the thirds one 
%           defines the step 
% file_out_X - filename for saving; empty list is now saving is required
% ds_rate - int, downsampling rate (reduces entries ds_rate times)
% alpha - significance level for outlier filtering; 'none' for no filtering
% Outputs:
% X_set - [N_t x N_fr x N_ch] matrix; contains scalogramms for each
%   electrodes. N_fr is defined by frequency_band
% D - data structure with additional information:
%     D.order - cell array of string names for each dimension
%     D.cutoff - cutoff value for artifacts removal; empty if no removal
%                was applied
%     D.neutral - mean ('neutral') values, used to replace atrifacts; empty
%                 if no removal was applied
%     D.edge_points - time stamps at edge_points;
%     D.time - all time points after downsampling
%     D.fs - sampling rate after downsampling
%     D.alpha = alpha
%     D.frequency_bands = frequency_bands;
%     D.scalo = X_set


if nargin < 7
    alpha = 0.01;
end
                                
d_ECoG = importdata(strcat(file_prefix, 'ECoG.csv'));

if ds_rate ~= 1
    d_ECoG.data = downsample(d_ECoG.data, ds_rate); 
    time = d_ECoG.data(:,1);
    fs =  1/mean(diff(time)); 
else
    time = d_ECoG.data(:,1);
    fs = 1000;
end


 %w\o downsampling, otherwise 
elect_columns = (2:length(d_ECoG.colheaders));
time_idx = time >= time_points(1) - time_interval - time_edge & time <= time_points(end);
sigs = d_ECoG.data(time_idx, elect_columns);
elect_columns = elect_columns - 1; % Because I don't have time offset now.

% edge_points = floor(time_edge * fs);

% run scalogram feature extraction w\o removing edge points:
% fun_per_elect = @(elect_num)scalo_by_electrode(elect_num, sigs, 0, ...
%                                             frequency_bands, fs, alpha);
% [features, cutoff, neutral] = arrayfun(fun_per_elect, elect_columns, 'UniformOutput', false);
features = cell(1, length(elect_columns)); 
cutoff = features;  neutral = features;
for el = elect_columns
    [features{el}, cutoff{el}, neutral{el}] = scalo_by_electrode(sigs(:, el), 0, ...
                                            frequency_bands, fs, alpha);
end

idx_edge_points = time(time_idx) < time_points(1) - time_interval;

edge_points = time(time_idx);
edge_points = edge_points(idx_edge_points);

D = {};
D.order = {'Time', 'Time bins', 'Frequency bins', 'Channels'};
D.cutoff = cat(1, cutoff{:});
D.neutral = cat(1, neutral);
D.edge_points = edge_points;
D.time = d_ECoG.data(:, 1);
D.fs = round(fs);
D.alpha = alpha;
D.frequency_bands = frequency_bands;


if ds_rate > 1 && sum(time_idx) <= 50000 || isempty(file_out)
    X_set = cat(3, features{:});
    clear features;
    % remove edge points for all scalogramms:
    X_set = X_set(~idx_edge_points, :, :, :);
    X_set(isnan(X_set)) = 0; % Converting trash data.
    D.scalo = log(X_set);
%     if ~isempty(file_out)
%         save(file_out, 'D');
%     end
else
    
    file_out = strsplit(file_out, '.mat');
    file_out = file_out(1);
    
    for ch = elect_columns  
        X_set = features{ch};
        X_set = X_set(~idx_edge_points, :, :, :);
        X_set(isnan(X_set)) = 0; % Converting trash data.
        D.scalo = log(abs(X_set));        
        save([file_out, '_nch_', num2str(ch), '.mat'], 'D');        
    end
end

end
