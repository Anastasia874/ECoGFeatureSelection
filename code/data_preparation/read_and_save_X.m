function [X_set, D, time_points] = read_and_save_X(file_prefix, time_points, time_edge, ...
                         time_interval, ntimebins, ...
                         frequency_bands, file_out_X, ds_rate, alpha, ...
                         tns_flag)

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
%     D.scalo - [N_t x N_fr x N_ch] matrix with scalogramms for each
%               electrode
%     D.X_set  - [nseconds x ntimebins x N_fr x N_ch] matrix; for each
%                       channel is N_ch contains reshaped scalogramm, where
%                       nseconds  = 1 - length(time_points) is the number 
%                       of overlapping one-second intervals in time_points
%                       (with step = 1)
                   
if ~exist('tns_flag', 'var')
    tns_flag = 0;
end

% D stores a [time x freaqs x electrodes] scalogram 
[~, D] = x_feature_extraction(file_prefix, time_points, time_interval, time_edge, ...
                            frequency_bands, [], ds_rate, alpha);
time_points = time_points(time_points <= D.time(end));                       
% returns 4-way matrix with dimorder [time x timebins x freqs x electrodes]
step_len = round(time_points(2) - time_points(1), 3);
X_set = dicretisize_matrix(D.scalo, ntimebins, D.time, time_points, ...
                            time_interval, ...
                            step_len);


D.reshaped_set = X_set;
if ~isempty(file_out_X)
    save(file_out_X, 'D');
end

                        
if ~tns_flag
    X_set = reshape(X_set, size(X_set, 1), []);
end

end