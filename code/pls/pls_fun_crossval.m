function err = pls_fun_crossval( ncomp, x_train, y_train, x_test, y_test, ...
                                 x_holdout, y_holdout, tensor_flag, ...
                                 regularization_struct)
if nargin < 8
    tensor_flag = 0;
end

if nargin < 9
    regularization_struct = {};
    regularization_struct.type = 'none';
end
    
% Function for crossvalidation.
if tensor_flag
   % Since matlab's crossval reshapes x_train and x_test into 2way matrices,
   % reshape them back:
   modes = size(x_holdout{1});
   modes(1) = size(x_train, 1);
   x_train = tensor(reshape(x_train, modes));
   modes(1) = size(x_test, 1);
   x_test = tensor(reshape(x_test, modes));
else
%     if ~ismatrix(x_train)
%         x_train = tenmat(x_train);
%         x_train = x_train.data;
%     end
    if ~ismatrix(x_test)
        x_test = tenmat(x_test);
        x_test = x_test.data;
    end    
%     [~,~,~,~, beta_] = plsregress(x_train, y_train, ncomp); % beta - coeffs for prediction.
%     plspredict = @(X)[ones(size(X, 1), 1) X] * beta_; % Function that makes prediction.
end

plspredict = regularized_pls(x_train, y_train, ncomp, tensor_flag, ...
                                regularization_struct);
                            
err = error_struct(plspredict, x_train, y_train, x_test, y_test, ...
                                 x_holdout, y_holdout);



end


% Old version.
% function criterion = pls_fun_crossval( ncomp, x_train, y_train, x_test, y_test )
% % Function for crossvalidation.
% [~,~,~,~, beta] = plsregress(x_train, y_train, ncomp); % beta - coeffs for prediction.
% 
% plspredict = @(X, beta)[ones(size(X, 1), 1) X] * beta; % Function that makes prediction.
% y_predicted = plspredict(x_test, beta);
% 
% 
% y_residuals = y_test - y_predicted; % Difference between predictions and actual values.
% 
% % Finding mean square error with respect to zero for each column (parameter). 
% mse_row = @(row)norm(y_residuals(row, :))/sqrt(length(y_residuals(row, :))); 
% residuals = arrayfun(mse_row, 1:size(y_residuals, 1));
% residuals_mean = mean(residuals);
% residuals_std = std(residuals);
% 
% %Finding Pearson correllation between rows of test and predited set. 
% corr_row = @(row)corr(y_test(row, :)', y_predicted(row, :)');
% correlations = arrayfun(corr_row, 1:size(y_test, 1));
% correlations_mean = mean(correlations);
% correlations_std = std(correlations);
% 
% criterion = {[residuals_mean, residuals_std, correlations_mean, correlations_std]};
% 
% end
% 
