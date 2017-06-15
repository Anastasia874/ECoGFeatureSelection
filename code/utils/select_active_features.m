function X = select_active_features(X, active_idx)

if nargin < 2
    active_idx = ones(size(X(1, :, :, :))) == 1;
end

assert(numel(active_idx) == numel(X(1, :, :, :)));
if length(size(X)) > 2
    X = fs_tensor_to_matrix(active_idx, X);
else
    X = X(:, active_idx);
end


end