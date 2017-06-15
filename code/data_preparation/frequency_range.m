function [fr_range, n_bands, fnj] = frequency_range(frequency_bands)

% Inputs:
% frequency_bands [n_bands x 3 matrix], each row specifies a fr. band: min
%   frequency, max frequency and the fr. step
% Outputs:
% fr_range - frequency range for all frequency bands
% fnj [1 x n_bands + 1] - specifies indices of frequencies for each band in
% fr_range

% % fnum = round((frequency_bands(:, 2) - frequency_bands(:, 1)) ./ ...
% %               frequency_bands(:, 3)) + 1;
% % fnj = cumsum([1; fnum]);
% % n_bands = size(frequency_bands, 1);
% % 
% % fr_range = ones(1, sum(fnum));

n_bands = size(frequency_bands, 1);
fnj = ones(1, n_bands + 1);
fr_range = [];
for nb = 1:n_bands
%    fr_range(fnj(nb):fnj(nb + 1) - 1) = ...
    newrange = ...
       frequency_bands(nb, 1):frequency_bands(nb, 3):frequency_bands(nb, 2);
   fnj(nb + 1) = fnj(nb) + length(newrange);
   fr_range = [fr_range, newrange];
end


end