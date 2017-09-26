function [X_set, D, time_points] = read_X_with_edge_effects(file_prefix, time_points, time_edge, ...
                         time_interval, ntimebins, ...
                         frequency_bands, ds_rate, alpha, ...
                         tns_flag)
                     
                     
fprintf('Running compuation with multiple edge effects. \n');

d_ECoG = importdata(strcat(file_prefix, 'ECoG.csv'));

if ds_rate ~= 1
    d_ECoG.data = downsample(d_ECoG.data, ds_rate); 
    time = d_ECoG.data(:,1);
    fs =  1/mean(diff(time)); 
else
    time = d_ECoG.data(:,1);
    fs = 1000;
end
time_points = time_points(time_points <= d_ECoG.time(end));   

 %w\o downsampling, otherwise 
elect_columns = (2:length(d_ECoG.colheaders));
time_idx = time >= time_points(1) - time_interval - time_edge & time <= time_points(end);
sigs = d_ECoG.data(time_idx, elect_columns);
elect_columns = elect_columns - 1; % Because I don't have time offset now.
clear d_ECoG;

features = cell(length(time_points)); 
cutoff = features;  neutral = features;
for t = 1:length(time_points)   
    time_idx = time <= time_points(t) & time > time_points(t) - time_interval;
    edge_points = sum(time_points(t) & time > time_points(t) - time_edge);
    feats = cell(1, length(elect_columns));
    for el = elect_columns
        [feats{el}, cutoff{t}{el}, neutral{t}{el}] = scalo_by_electrode(...
                                                sigs(time_idx, el), ...
                                                edge_points, ...
                                                frequency_bands, fs, alpha);
    end
    feats = cat(3, feats{:}); % [~~time_interval x nfreqs x channels]
    features{t} = discrete_matrix(feats, ntimebins);
end

X_set = cat(4, features); clear features;
X_set = permute(X_set, [2, 3, 4, 1]);

D = {};
D.order = {'Time', 'Time bins', 'Frequency bins', 'Channels'};
D.cutoff = cat(1, cutoff{:});
D.neutral = cat(1, neutral);
D.edge_points = edge_points;
D.time = time;
D.fs = round(fs);
D.alpha = alpha;
D.frequency_bands = frequency_bands;


if ~tns_flag
    X_set = reshape(X_set, size(X_set, 1), []);
end
D.scalo = log(X_set);
                     
end