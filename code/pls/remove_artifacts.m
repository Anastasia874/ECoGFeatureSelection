function scalo_features = remove_artifacts(scalo_features, alpha)
% Removes artifacts from scalogram eature matrix (for each channel)
% scalo_features is a 4-way matrix, with the following order of dimensions: 
% [time_points, time_bins, freq_bins, channels]
% For each frequency and channel scalogram values shoud follow
% approximate gamma distribution. Outliers are detected sequentially (by
% one) and replaced with mean values

if nargin < 2
    alpha = 0.05;
end

[n_time_points, n_time_bins, n_freqs, n_channels] = size(scalo_features);

scalo_features = reshape(scalo_features, [n_time_points * n_time_bins, ...
                                                      n_freqs, n_channels]);


for ch = 1:n_channels
    for fr = 1:n_freqs
        X = squeeze(scalo_features(:, fr, ch));    
        X = remove_artifacts_from_scalogram(X, alpha);
    end 
    scalo_features(:, fr, ch) = X;    
end


end


function X = remove_artifacts_from_scalogram(X, alpha)
    [phat, ~] = gamfit(X, alpha);
    cp = gamcdf(X, phat(1), phat(b));
    [max_cp, idx] = max(cp);
    
    if max_cp > 1 - alpha
        X(idx) = phat(1);
        X = remove_artifacts_from_scalogram(X, alpha);
    else
       return;
    end
    
    
end