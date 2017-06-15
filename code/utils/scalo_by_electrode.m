function [scalo, cutoff, neutral] = scalo_by_electrode(signal, edge_points, ...
                                                frequency_bands, fs, alpha)

cutoff = [];
neutral = [];


trace = 0;
wave = 7; % Have almost no idea what it means.

MAX_SIZE = 50000;
signal_len = length(signal);
if signal_len > MAX_SIZE
    idx = 1:MAX_SIZE:signal_len;
    edge_points = [edge_points, ones(1, length(idx)-1)*100];
else
    idx = 1;
end


fnum = round((frequency_bands(:, 2) - frequency_bands(:, 1)) ./ ...
              frequency_bands(:, 3)) + 1;
fnj = cumsum([1; fnum]);
scalo = zeros(length(signal), sum(fnum));
n_bands = size(frequency_bands, 1);

for i = 1:length(idx)
    idxi = idx(i) - edge_points(i):min(idx(i) + MAX_SIZE - 1, signal_len);   
    timestamp = 1:length(idxi);
    for nb = 1:n_bands
        fmin = frequency_bands(nb, 1);
        fmax = frequency_bands(nb, 2);
        newscalo = tfrscalo(signal(idxi), timestamp, wave, fmin/fs, min([fmax/fs, 0.5]), fnum(nb), trace);
        scalo(idxi, fnj(nb):fnj(nb+1)-1) = ...
            newscalo(:, (edge_points + 1:end))'; 
    end
end


if ~strcmp(alpha, 'none')    
    cutoff = zeros(1, sum(fnum));
    neutral = zeros(1, sum(fnum));
    % if not 'none', alpha shoud be numeric
    assert(isfloat(alpha), 'alpha shoud be float or string "none" for no artifact removal \n');
    for nb = 1:n_bands
        [scalo(:, fnj(nb):fnj(nb+1)-1), cutoff(fnj(nb):fnj(nb+1)-1), ...
            neutral(fnj(nb):fnj(nb+1)-1)] = ...
      remove_artifacts_from_scalogram(scalo(:, fnj(nb):fnj(nb+1)-1), alpha);
    end
end


% scalo = zscore(scalo')';

end