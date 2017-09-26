function [err, x, complexity, idx_selected, pars, pvals, ak, Qb] = QP_feature_selection(...
                                                X, y, ncv, params, ...
                                                X_holdout, y_holdout,...
                                                nfeats)
% Quadratic programming feature selection
% Inputs:
% X - [nsamples x nfeats1 (x nfeats2 x ...)] matrix (or tensor) with input 
%     features
% y - target vector / matrix
% ncv - number of crossvalidation splits
% params - structure with algorithm parameters:
%     params.sim - defines similarity function ('correl')
%     params.rel - defines relevance function. The only option is 'correl'
%     params.tns_flag - 1 for NQPFS, 0 for original QPFS
%     params.rank - rank of decomposition for similarity computation;
%     params.ntries - number of trials to solve optimization problem;
%     params.ff - forgetting factor in (0, 1) for batch processing;
%     params.Qb - history of Q and b batch computations;
% X_holdout - cell array with feature matrices for hold-out evaluations
% y_holdout - cell array with targets for hold-out evaluations
% nfeats - list with numbers of features to select
% Outputs:
% err - {ncvs x 1} cell array with error structures (see error_struct.m)
% x - {ncvs x 1} cell array with optimized values of structure variable
% idx_selected {ncvs x 1} with indices of selected features (binary
%                       matrices [nfeatures x n_threshold values])
% pars - {ncvs x 1} with [(nfeatures + 1) x n_threshold] parameters of 
%                  linear regression, values for not selected features are 
%                  zeros. The top row is for intercept values
% pvals - {ncvs x 1} with [(nfeatures + 1) x n_threshold] p-values for 
%                  estimated parameters stored in pars
% ak - tensor version of x, see solve_tns_opt_problem.m

% Do not forget to include your path to Mosek:
addpath('C:\Program Files\Mosek\8\toolbox\r2014a');



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
ntries = params.ntries;
ff = params.ff;
Qb = params.Qb;

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
    
    solved = 0;
    ntry = 1; 
    while ~solved && ntry <= ntries
        [Q, b] = create_opt_problem(X_train, y_train, sim, rel, rank, ...
                                    tns_flag, [Qb, ff]);
        fprintf('Solving optimization problem, ntry %i / %i \n', ntry, ntries);
        topt = tic;
        [x{cv}, solved, ak{cv}, msg] = solve_opt_problem(Q, b, params);     
        toc(topt);
        ntry = ntry + 1;
    end    
    if ~solved 
        fprintf(['%i attempts to solve optimization problem with %s of rank',...
            ' %i failed (%s)\n'], ntries, sim, rank, msg);
        continue;
    end
    Qb = {Q, b};
    
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