function [err, allw, idx_selected, pvals] = eval_selection(A, ...
                                                X_train, y_train, ...
                                                 X_test, y_test, ...
                                                 X_holdout, y_holdout, ...
                                                 threshold)


% Calculate prediction metrics for all possible active sets to evaluate  
% feature selection quality.
%
% Inputs:
% A - feature selection variable, returned by solve_opt_problem. Stored in 
%     the matrix of the same size as the feature set. Takes values in [0, 1]
% X_train, y_train - trainig data. If empty arrays are passed, only selection 
%                    stats (complexity and idx_selected) will be computed    
% X_test, y_test - testing data. Pass empty arrays, if for no evaluation on 
%                  training data 
% X_holdout, y_holdout - holdout data, each a (possibly empty) cell array
%                        corresponding to a holdout sample
% threshold - list of threshold values to convert A from [0, 1] range to {0, 1}
%
% Outputs:
% complexity - [len(threshold) x 1] number of included features by threshold 
%             values
% err - [1 x len(threshold)] cell array with error structures (see error_struct.m)
% allw - [nfeatures x ntargets x len(threshold)] matrix of estimated parameters
%        for active features
% pvals - [nfeatures x ntargets x len(threshold)] matrix of pvalues for
%          tetsing hypothesis that the estimated parameters are different
%          from zero
% idx_selected - [nfeatures x len(threshold)] boolean matrix, indicates 
%                feature inclusions into the model        
                                            


nfeats = numel(A);
err = cell(1, nfeats);
err = padd_error_struct(err, numel(X_holdout));
idx_selected = zeros(nfeats, length(threshold));


if ~isempty(y_train)
    allw = zeros(nfeats + 1, size(y_train, 2), length(threshold));
else
    allw = [];
end
pvals = allw;
niters = length(threshold);
progress_idx = round(linspace(1, niters, 11));

complexity = 0;
for i=1:niters
    if any(progress_idx == i)
        fprintf(' * %s', '');
    end
    active_idx = A >= threshold(i);
    idx_selected(:, i) = active_idx(:);
        
    if sum(idx_selected(:, i)) == 0
        break;
    end
    
    if isempty(X_train)
        continue;
    end    
    if i > 1 && sum(idx_selected(:, i)) == complexity
        continue;
    else
        complexity = sum(idx_selected(:, i));
        [w, pvs] = regression_pars(select_active_features(X_train, active_idx), y_train);  
        allw([true; idx_selected(:, i) == 1], :, i) = w;
        pvals([true; idx_selected(:, i) == 1], :, i) = pvs;
        err{complexity} = error_struct(@(x) lmregress(w, ...
                                    select_active_features(x, active_idx)),...
                                    X_train, y_train, ...
                                    X_test, y_test, X_holdout, y_holdout);
       
    end
end
fprintf('%s\n', '');

end

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

% function [complexity, err, allw, idx_selected] = eval_tns_selection(A, ...
%                                                  X_train, y_train, ...
%                                                  X_test, y_test, ...
%                                                  X_holdout, y_holdout, ...
%                                                  threshold)
%                                              
% nfeats = numel(A);
% complexity = zeros(nfeats, 1);
% err = cell(1, nfeats);
% idx_selected = zeros(nfeats, length(threshold));
% if ~isempty(y_train)
%     allw = zeros(nfeats, size(y_train, 2), length(threshold));
% else
%     allw = [];
% end
% for i=1:length(threshold)
% %     fprintf('i = %d\n', i);
%     idx_selected(:, i) = A(:) >= threshold(i);
%     n_active = sum(idx_selected(:, i));
%     complexity(i) = n_active;
%     
%     if n_active == 0
%         break;
%     end
%     if isempty(X_train)
%         continue;
%     end    
%     if i > 1 && n_active == complexity(i-1)
%         continue;
%     else
%         w = regression_pars(fs_tensor_to_matrix(A >= threshold(i), X_train), y_train);
% %         allw(:, :, i) = w;
%         err{complexity(i)} = error_struct(@(x) lmregress(w,...
%                                    fs_tensor_to_matrix(A >= threshold(i), x)), ...
%                                    X_train, y_train, ...
%                                    X_test, y_test, X_holdout, y_holdout);
%         
%        
%     end
% end
% 
% err = padd_error_struct(err);
% 
% end