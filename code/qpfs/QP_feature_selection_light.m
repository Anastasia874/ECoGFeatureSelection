function x = QP_feature_selection_light(X, y, ncv, params)

addpath('C:\Program Files\Mosek\8\toolbox\r2014a');
% String indications for way to compute similarities and relevances
if nargin < 3
    ncv = 5;
end

if nargin < 4
    sim = 'correl';
    rel = 'correl';
    tns_flag = 0;
    rank = [];
else
    rank = params.rank;
    sim = params.sim;
    rel = params.rel;
    tns_flag = params.tns_flag;
end

if ~tns_flag
   X = reshape(X, size(X, 1), []); 
end


m = size(X, 1);
idx_splits = round(linspace(0, m, ncv + 1));
shuffled_idx = randperm(m);
% threshold = 1e-3:1e-5:0.1;


x = cell(1, ncv);
for cv = 1:ncv
    fprintf('QPFS, iteration %i / %i \n', cv, ncv);
    idx_cv = ismember(shuffled_idx, idx_splits(cv)+1:idx_splits(cv + 1));
    X_train = X(~idx_cv, :, :, :); 
    y_train = y(~idx_cv, :);
    
    solved = 0;
    ntries = 5; ntry = 1;
    while ~solved && ntry < ntries
        [Q, b] = create_opt_problem(X_train, y_train, sim, rel, rank, tns_flag);
        [x{cv}, solved] = solve_opt_problem(Q, b, params);     
        ntry = ntry + 1;
    end
    
    if ~solved 
        fprintf(['%i attempts to solve optimization problem with %s of rank',...
            ' %i failed \n'], ntries, sim, rank);
    end
    

end


    
end