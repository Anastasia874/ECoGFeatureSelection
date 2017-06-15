function err = nan_errors(x_holdout)

% Returns error structure filled with nans, used for paddinf in evaluation
% of QP feature selection

err.mse = nan;
err.crr = nan;
err.dtwd = nan;
err.mse_train = nan;
err.crr_train = nan;
err.dtwd_train = nan;
err.made = nan;
err.made_train = nan;

if ~isempty(x_holdout)
    if ~iscell(x_holdout)
        x_holdout = {x_holdout};
    end
    err.crr_ho = cell(1, length(x_holdout));
    for i = 1:length(x_holdout)
        err.crr_ho{i} = nan;
    end
end

end