function [X, cutoff, neutral] = remove_artifacts_from_scalogram(X, alpha, block_size)

if nargin < 3
    block_size = round(size(X, 1)* 0.01);
end
    

nfreqs = size(X, 2);
cutoff = ones(1, nfreqs);
neutral = ones(1, nfreqs);
fprintf(['Filtering scalogram with %d frequency bins and %d time entries; ', ...
          'block size %d; alpha %0.2f \n'], nfreqs, size(X, 1), block_size, alpha);
n_filtered = 0;
tic
for f = 1:nfreqs
   [X(:, f), cutoff(f), neutral(f), idx_filtered] = remove_artifacts_from_frequency(X(:, f), ...
                                        alpha, block_size);
    n_filtered = n_filtered + length(idx_filtered);
end
toc;
fprintf('Replaced %0.4f objects \n', n_filtered / numel(X));

end


function [XX, cutoff, neutral, idx_f] = remove_artifacts_from_frequency(X, alpha, block_size)
idx_f = []; idx = 1:length(X);
XX = X; 

if nargin < 3
    block_size = 50;
end

MAX_ITERS = 10000;


[phat, ~] = gamfit(X(idx), alpha);
cp = gamcdf(X, phat(1), phat(2));
[max_cp, idx_outl] = max(cp);


while  max_cp > 1 - alpha
    if MAX_ITERS < length(idx_f)        
        fprintf('Max number (%d) of filtering steps reached; %0.2f entries with p < 0.2f left', ...
            MAX_ITERS, sum(cp > 1 - alpha), 1 - alpha);
        break;
    end
    idx_f = [idx_f, idx_outl];
    idx = idx(~ismember(idx, idx_outl));
    XX(idx_outl) = mean(X(idx));
    [phat, ~] = gamfit(X(idx), 1 - alpha);
    cp = gamcdf(XX, phat(1), phat(2));
    [max_cp, idx_outl] = select_oultliers(cp, alpha, block_size);
end

if ~isempty(idx_f) 
    bad_values = X(idx_f);
    cutoff = min(bad_values);
else
    cutoff = gaminv(1 - alpha, phat(1), phat(2));
end

neutral = phat(1) * phat(2);
    
    
end


function [max_cp, idx_outl] = select_oultliers(cp, alpha, block_size)

if block_size == 1
    [max_cp, idx_outl] = max(cp);
else
    idx = 1:length(cp);
    idx_cp = idx(cp > 1-alpha);
    if isempty(idx_cp)
        [max_cp, idx_outl] = max(cp);
        return;
    end
    [cp, idx_sorted_cp] = sort(cp(idx_cp), 'descend');
    idx_outl = idx_cp(idx_sorted_cp(1:min([block_size, length(idx_cp)])));
    max_cp = cp(1);
end

end