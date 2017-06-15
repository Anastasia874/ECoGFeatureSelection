function [x, solved, ak, msg] = solve_opt_problem(Q, b, params)
% Function solves the quadratic optimization problem stated to select
% significance and noncollinear features
%
% Input:
% Q - [n, n] - matrix of features similarities
% b - [n, 1] - vector of feature relevances
%
% Output:
% x - [n, 1] - solution of the quadratic optimization problem
% solved - boolean, solution status
%
% Based on solveOptProblem from QPFeatureSelection toolbox
% by Alexandr Katrutsa, 2016 (https://github.com/amkatrutsa/QPFeatureSelection)

msg = '';
if iscell(Q)
   if nargin < 3
       R = 10;
       iters = 5;
       init = [];
   else
        iters = params.iters;
        R = params.Arank;
        init = params.init;
   end
   [x, solved, ak, msg] = solve_tns_opt_problem(Q, b, iters, R, init);
   return
end



n = size(Q, 1);
cvx_solver Mosek

try
    cvx_begin  quiet
        variable x(n, 1) nonnegative;
        minimize (x'*Q*x - b'*x)
        subject to
            norm(x, 1) <= 1;
    cvx_end
    solved = 1;
catch ME
    msg = ME.message;
    cvx_clear;
    x = ones(1, n);
    solved = 0;    
end
ak = x;        

end

