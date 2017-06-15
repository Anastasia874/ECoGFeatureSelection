function [corrs, mdl] = td_y_electrode_corrs(y, x, delays)

% Computes matrix of correleation between y and time-delayed ECoG time
% series
% Inputs:
% y - [T x 1] motion time series
% x - [T x N_ch] ECoG time series for each electrode. Time series are
%                resampled to have the same number of observations as y
% delays - [1 x N_d] row vector with time delays (symmetric, in seconds) to consider. 
%                    Negative values correspond to the ECoG signal
%                    preceeding the motion
% Outputs:
% corrs - [N_ch, N_d] correlation matrix

if ~exist('delays', 'var')
delays = -1:0.05:1;
end

mdl = floor(length(delays)/2);



corrs = zeros(size(x, 2), length(delays));
for i = 1:length(delays) 
     corrs(:, i) = corr(x(i:end - 2*mdl - 1 + i, :), ...
                                          y(mdl + 1:end-mdl));
end

end