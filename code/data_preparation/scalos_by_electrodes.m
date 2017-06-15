function scalos = scalos_by_electrodes(x, frequency_bands, fs, filtering_alpha, ...
                                                                electrodes)

% Computes matrix of correleation between y and time-delayed ECoG time
% series
% Inputs:
% x - [T x N_ch] ECoG time series for each electrode. Time series are
%                resampled to have the same number of observations as y
% frequency_bands - [N_b x 3] frequency bands for scalograms (see 
%                             frequency_range for details)
% fs - sampling rate, Hz
% electrodes - (optional) row vector, indices of specific electrodes
% Outputs:
% scalos - {1 x N_ch} cell array with [T x N_fr] scalos

if ~exist('electrodes', 'var')
    electrodes = 1:size(x, 2);
end
                

scalos = cell(1, size(x, 2));
for el = electrodes       
            [scalos{el}, ~, ~] = scalo_by_electrode(x(:, el), 0, ...
                                                      frequency_bands, ...
                                                      fs, filtering_alpha);
end


end