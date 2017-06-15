function [sizes1, sizes2] = estimate_dataset_size(time_points, params, tns_flag)
                                        
                                        
time_interval = params.time_interval;
time_edge = params.time_edge;
ds_rate = params.ds_rate;
ntimebins = params.ntimebins;
frequency_bands = params.frequency_bands;

% Use the number of time points in '20090121S1_FTT_A_ZenasChao_csv_ECoG32-Motion10'
% for estimation:
ntimepoints_raw = 993793; 
time = (0:1:(ntimepoints_raw - 1))/1000;
nelectrodes = 32;

% file_prefix = ['../data/', experiment_name, '/'];
% d_ECoG = importdata(strcat(file_prefix, 'ECoG.csv'));
% time = d_ECoG.data(:, 1);
% nelectrodes = size(d_ECoG.data, 2);
% clear d_ECoG;

time = downsample(time, ds_rate);
fs = 1000/ds_rate; 

frequency_bands = frequency_bands(frequency_bands(:, 1) < 0.5 * fs, :);   
frequency_bands(end, 2) = min(frequency_bands(end, 2), 0.5 * fs);
fr_range = frequency_range(frequency_bands);
nfreqs = length(fr_range);


time_idx = time >= time_points(1) - time_interval - time_edge & time <= time_points(end);
idx_edge_points = time(time_idx) < time_points(1) - time_interval;

edge_points = time(time_idx);
edge_points = edge_points(idx_edge_points);

sizes1 = [sum(time_idx) - length(edge_points), nfreqs, nelectrodes];
sizes2 = [length(time_points), ntimebins, nfreqs, nelectrodes];

if ~tns_flag
    sizes2 = [sizes2(1), prod(sizes2(2:end))];
end
str1 = strjoin(arrayfun(@(x) num2str(x), sizes1, 'UniformOutput', 0), ', ');
str2 = strjoin(arrayfun(@(x) num2str(x), sizes2, 'UniformOutput', 0), ', ');

fprintf('Feature set sizes: raw [%s] reshaped into [%s]; number of feats %i \n', ...
                    str1, str2, prod([ntimebins, nfreqs, nelectrodes]));

end