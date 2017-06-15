function err = error_struct(predictfun, x_train, y_train, x_test, y_test, ...
                                 x_holdout, y_holdout)



if ~isempty(x_train)
    y_train_pred = predictfun(x_train);
    smse_train = scaled_mse(y_train_pred, y_train);
    crr_train = correlation_error(y_train_pred, y_train);
    dtw_dist_train = dtw_c(y_train_pred, y_train); % nan
    made_train = made_error(y_train_pred, y_train);
else
    smse_train = nan;
    crr_train = nan;
    dtw_dist_train = nan;
    made_train = nan;
end

% plot_prediction_res(y_predicted, y_test, ['kfold_', num2str(ncomp)]);
 
if ~isempty(x_test)    
    y_predicted = predictfun(x_test);
    smse = scaled_mse(y_predicted, y_test);
    crr = correlation_error(y_predicted, y_test);
    dtw_dist = dtw_c(y_predicted, y_test); % nan
    made = made_error(y_predicted, y_test);
else
    smse = nan;
    crr = nan;
    dtw_dist = nan; 
    made = nan;
end


% y_diff = y_test - y_predicted;
% norm_row = @(row)norm(y_diff(row, :));
% norm_rows = arrayfun(norm_row, 1:size(y_diff, 1));
% mse = mean(norm_rows);






% dtw_dist = dtw(y_predicted, y_test);

err.mse = smse;
err.crr = crr;
err.dtwd = dtw_dist;
err.mse_train = smse_train;
err.crr_train = crr_train;
err.dtwd_train = dtw_dist_train;
err.made = made;
err.made_train = made_train;

err.crr_ho = {};
if nargin > 6 && ~isempty(x_holdout)
    if ~iscell(x_holdout)
        x_holdout = {x_holdout};
        y_holdout = {y_holdout};
    end
    err.crr_ho = cell(1, length(x_holdout));
    for i = 1:length(x_holdout)
        y_pred_ho = predictfun(x_holdout{i});
        err.crr_ho{i} = correlation_error(y_pred_ho, y_holdout{i});
    end
end



end


function made = made_error(yhat, y)

made = sum(diff(yhat))/sum(diff(y));

end