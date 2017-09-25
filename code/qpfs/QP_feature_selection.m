function [err, x, complexity, idx_selected, pars, pvals, ak, Qb] = QP_feature_selection(...
                                                X, y, ncv, params, ...
                                                X_holdout, y_holdout,...
                                                nfeats)

if nargin < 3
    ncv = 5;
end

if nargin < 4
    params.sim = 'correl';
    params.rel = 'correl';
    params.tns_flag = 0;
    params.rank = [];
    params.ntries = 5;
    params.ff = 0.8;
    params.Qb = [];
end

if nargin < 7
    nfeats = [];
end

rank = params.rank;
sim = params.sim;
rel = params.rel;
tns_flag = params.tns_flag;


if ~tns_flag
   X = reshape(X, size(X, 1), []); 
end


m = size(X, 1);
idx_splits = round(linspace(0, m, ncv + 1));
shuffled_idx = randperm(m);
% threshold = 1e-3:1e-5:0.1;


MAX_EVALS = 1000;
complexity = zeros(min(MAX_EVALS, numel(X(1, :, :, :))), ncv);
idx_selected = cell(1, ncv);
ak = cell(1, ncv);
err = cell(1, ncv);
x = cell(1, ncv);
pars = cell(1, ncv);
pvals = cell(1, ncv);
for cv = 1:ncv
    titer = tic;
    fprintf('QPFS, iteration %i / %i \n', cv, ncv);
    if ncv == 1
        X_train = X; X_test = [];
        y_train = y; y_test = [];
    else
        idx_cv = ismember(shuffled_idx, idx_splits(cv)+1:idx_splits(cv + 1));
        X_train = X(~idx_cv, :, :, :); X_test = X(idx_cv, :, :, :);
        y_train = y(~idx_cv, :); y_test = y(idx_cv, :, :);
    end
    
    ntries = 5;
    ntry = 1;
    while ntry < ntries
        try
            [x{cv}, ak{cv}, Qb, solved, msg] = qpfs_create_and_solve(X_train, y_train, params);
            if ~solved 
                fprintf(['%i attempts to solve optimization problem with %s of rank',...
                    ' %i failed (%s)\n'], ntries, sim, rank, msg);                
                continue;
            end
        catch 
        end
        ntry = ntry + 1;
    end
    
    threshold = sort(x{cv}(:))';
    if ~isempty(nfeats)
        threshold = threshold(length(threshold) - nfeats);
    elseif length(threshold) > MAX_EVALS
        threshold = threshold(length(threshold) - MAX_EVALS + 1:end);
    end
    
    [err{cv}, pars{cv}, idx_selected{cv}, pvals{cv}] = eval_selection(x{cv},...
                                                X_train, y_train, ...
                                                X_test, y_test, ...
                                                X_holdout, y_holdout, ...
                                                threshold);


    disp('QPFS iter done');
    toc(titer);
end

err = cat(1, err{:});
    
end