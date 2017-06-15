function [Q, b] = create_tns_opt_problem(X, y, sim, rel, rank, oldQb)

old = ~isempty(oldQb) && ~isempty(oldQb{1});

X = tensor(X);
rank = min(rank, X.size(1));


dims = X.size;
if old
    for dim = 1:length(dims) - 1
       tmp{dim} = {oldQb{1}{dim}, oldQb{2}, oldQb{3}};
    end
    oldQb = tmp;
    clear tmp;
else
    oldQb = cell(1, length(dims) - 1);
end


Q = cell(1, length(dims) - 1);

dim_str = strjoin(arrayfun(@(i) num2str(i), dims, 'UniformOutput', 0), ', ');

if strcmpi(sim, 'tucker')
    rank = [rank, X.size(2:end)];
    rank_str = strjoin(arrayfun(@(i) num2str(i), rank, 'UniformOutput', 0), ', ');
    fprintf('Computing Tucker decomposition of rank [%s] for [%s]\n', rank_str, dim_str); 
    % tucker = tic;
    % T = tucker_als(X, rank, struct('printitn', 0)); % then reach T.U{dim}
    % toc(tucker);

    for dim = 2:length(dims)
        U = nvecs(X, dim, rank(dim)-1); % subtract 1, so that number of eigenvalues k < n
        [Q{dim-1}, ~] = create_opt_problem(U', [], 'correl', rel, rank, 0, oldQb{dim-1});
    %     [Q{dim-1}, ~] = create_opt_problem(T.U{dim}', [], 'correl', rel, rank, 0);
    end
end

if strcmpi(sim, 'parafac')
    fprintf('Computing PARAFAC decomposition of rank [%i] for [%s]\n', rank, dim_str); 
    parafac = tic;
    T = parafac_als(X, rank, struct('printitn', 0)); % then reach T.U{dim}
    toc(parafac);
    
    core = diag(T.lambda);
    for dim = 2:length(dims)
        [Q{dim-1}, ~] = create_opt_problem(core * T.U{dim}', [], 'correl', ...
                        rel, rank, 0, oldQb{dim-1});
    end    
    
end

if strcmpi(sim, 'unfold')
    for dim = 2:length(dims)
        Xd = tenmat(X, dim);
        [Q{dim-1}, ~] = create_opt_problem(Xd.data, [], 'correl', rel, rank, ...
            0, oldQb{dim-1});
    end    
    
end


X = X.data;
X = reshape(X, dims(1), []);
[~, b] = create_opt_problem(X, y, 'none', rel, rank, 0, oldQb{1});
b = reshape(b, dims(2:end));

end