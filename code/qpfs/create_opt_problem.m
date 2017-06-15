function [Q, b] = create_opt_problem(X, y, sim, rel, rank, tns_flag, oldQb)
% Function generates matrix Q and vector b 
% which represent feature similarities and feature relevances
%
% Input:
% X - [m, n] - design matrix
% y - [m, 1] - target vector
% sim - string - indicator of the way to compute feature similarities,
% support values are 'correl' and 'mi'
% rel - string - indicator of the way to compute feature significance,
% support values are 'correl', 'mi' and 'signif'
% rank - rank of decomposition for similarity computation (for tensor
%       inputs)
% tnf_flag - indicates if the problem should be solved in tensor or in
% matrix format
%
% Output:
% If tns_flag is false:
% Q - [n, n] - matrix of features similarities
% b - [n, 1] - vector of feature relevances
% otherwise
% Q - {[n1, n1], [n2, n2], [n3, n3]} - cell array with similarity matrices
% b - [n1, n2, n3] - 3-way relevance matrix
%
% Author: Alexandr Katrutsa, 2016 
% E-mail: aleksandr.katrutsa@phystech.edu

if nargin < 7
    oldQb = {};
end

old = ~isempty(oldQb) && ~isempty(oldQb{1});
if old
   oldQ = oldQb{1};
   oldB = oldQb{2};
   ff = oldQb{3}; % forgetting_factor;
end

if tns_flag == 1
    [Q, b] = create_tns_opt_problem(X, y, sim, rel, rank, oldQb);
    return
end

if strcmp(sim, 'none')
    Q = 1;
else    
    if strcmp(sim, 'correl') || strcmp(sim, 'Tucker')
        Q = abs(corrcoef(X));
    elseif strcmp(sim, 'cov')
        Q = abs(corrcoef(X));
    else
        if strcmp(sim, 'mi')
            Q = zeros(size(X, 2));
            for i = 1:size(Q, 2)
                for j = i:size(Q, 2)
                    Q(i, j) = information(X(:, i)', X(:, j)');
    %                 Q(i, j) = mutualinfo(X(:, i), X(:, j));
                end
            end
            Q = Q + Q' - diag(diag(Q));
        end
%         lambdas = eig(Q);
%         min_lambda = min(lambdas);
%         if min_lambda < 0
%             Q = Q - min_lambda * eye(size(Q, 1));
%         end
    end
end

% alpha = 0.1; step = 0.1;
% while det(Q + alpha*eye(size(Q))) <= 0 
%     alpha = alpha + step;
% end
% Q = Q + alpha*eye(size(Q));
% fprintf('Added regularization term alpha*I with alpha = %0.2f, det(Q) = %e\n', ...
%             alpha, det(Q));

if old
    Q = oldQ * (1 - ff) + Q * ff;
end
if det(Q) <= 0
    Q = (Q + Q')/2;
    [V, D] = eig(Q);
    Q = V * max(D, 0) / V;
    fprintf('Removed %i eigeinvalues <= 0, det(Q) = %e\n', sum(diag(D) <= 0), det(Q));
end



if isempty(y)
    b = 0;
    return
end

if strcmp(rel, 'correl')
    b = max(abs(corr(X, y)), [], 2);
    if old
        oldB = reshape(oldB, size(b));
        b = oldB * (1 - ff) + b * ff;
    end
    return
end

if strcmp(rel, 'mi')
    b = zeros(size(X, 2), 1);
    for i = 1:size(X, 2)
        b(i) = information(y', X(:, i)');
%         b(i) = mutualinfo(y, X(:, i));
    end
    if old
        b = oldB * (1 - ff) + b * ff;
    end
    return
end
if strcmp(rel, 'signif')
   lm = fitlm(X, y);
   p_val = lm.Coefficients.pValue(2:end);
   idx_zero_coeff = find(abs(lm.Coefficients.Estimate(2:end)) < 1e-7);
   nan_idx = isnan(p_val);
   p_val(nan_idx) = ones(sum(nan_idx), 1);
   b = 1 - p_val ./ sum(p_val); 
   b(idx_zero_coeff) = zeros(length(idx_zero_coeff), 1);
   if old
        b = oldB * (1 - ff) + b * ff;
    end
   return 
end


end


