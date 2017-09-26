function [x, ak, Qb, solved, msg] = qpfs_create_and_solve(X_train, y_train, params)


% addpath('C:\Program Files\Mosek\8\toolbox\r2014a');

if nargin < 3
    params.sim = 'correl';
    params.rel = 'correl';
    params.tns_flag = 0;
    params.rank = [];
    params.ntries = 5;
    params.ff = 0.8;
    params.Qb = [];
end

rank = params.rank;
sim = params.sim;
rel = params.rel;
tns_flag = params.tns_flag;
ntries = params.ntries;
ff = params.ff;
Qb = params.Qb;

if ~tns_flag
   X_train = reshape(X_train, size(X_train, 1), []); 
end

solved = 0;
ntry = 1; %!!
while ~solved && ntry <= ntries
    [Q, b] = create_opt_problem(X_train, y_train, sim, rel, rank, tns_flag, [Qb, ff]);
    fprintf('Solving optimization problem, ntry %i / %i \n', ntry, ntries);
    topt = tic;
    [x, solved, ak, msg] = solve_opt_problem(Q, b, params);     
    toc(topt);
    ntry = ntry + 1;
end    

Qb = {Q, b};

end