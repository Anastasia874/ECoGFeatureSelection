function X = dicretisize_matrix(X, ntimebins, time, ds_time, epoch_len, ...
                step_len)

% Reshape scalograms into epochs and discretize reshaped matrices into ntimebins
% Inputs:
% X - [N_t x N_fr x N_ch] scalogramms for N_ch electrodes
% ntimebins - number of time bins in discretized matrix
% time - time points for which features calculation is required
% ds_time - all time points after downsampling
% epoch_len - length in seconds one epoch
% step_len - step length in seconds between epoch; epoch_len < step_len
%            means that epochs overlap
% Outputs:
% X - [N_epochs x ntimebins x N_fr x N_ch] matrix

% check dimensions:
[timedims, freqdims, channelbins] = size(X);
fprintf(['Discretizing matrix with %d time enties, %d frequency bins and', ... 
                        ' %d channel entries into %d timebins \n'], ...
                        timedims, freqdims, channelbins, ntimebins);

epoch_ends = ds_time(1):step_len:ds_time(end);
n_epochs = length(epoch_ends);
time = time(time > ds_time(1) - epoch_len & time <= ds_time(end));

% % arrayfun and cellfun are slow, don't use them
% bin_features = arrayfun( @(i) X(time >= epoch_starts(i) & ...
%                                 time < epoch_starts(i) + epoch_len, :, :), ...
%                                 1:n_epochs,...
%                                 'UniformOutput', 0);
% X = cellfun( @(x) discrete_matrix(x, ntimebins), bin_features, ...
%                 'UniformOutput', 0);


reshaped = cell(1, n_epochs);
tic
for i = 1:n_epochs
    bin_features = X(time > epoch_ends(i) - epoch_len & time <= epoch_ends(i), :, :);
    reshaped{i} = discrete_matrix(bin_features, ntimebins);
end
toc

X = cat(4, reshaped{:}); % dim order: timebins, freqbins, channels, timepoints
X = permute(X, [4, 1, 2, 3]);


end

function X = discrete_matrix(X, nbins)

% averaging along axis 1 
edges = round(linspace(1, size(X, 1), nbins + 1));
X = arrayfun(@(i) mean(X(edges(i):edges(i+1), :, :), 1), 1:nbins, ...
                        'UniformOutput', 0);
X = cat(1, X{:});

end