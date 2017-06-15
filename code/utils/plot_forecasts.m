function plot_forecasts(time_points, xtrain, ytrain, xtest, ytest, methods, postfix, nfeats, ntrain, ntest, sm)
% Plot forecasted time series, using selected selected features 
% Inputs:
% time_points - list of time stamps for both train and test
% xtrain, ytrain - training data
% xtest, ytest - test data. 
% methods - cell array of strings with feature selection methods (the string includes
%           dataset information, name of the method and its parameters, i.e '2D_0p65_log_Tucker_1_1')
% postfix - another string, specifies the target marker and subject: '_wrxyz_0p05_frscale_15_nfolds_5_K1_ZenasChao_csv_ECoG64-Motion8'
% nfeats - number of features to use in the forecasting model
% ntrain, ntest - number of training and testing points to plot
% sm - smoothing parameter (0 for no smoothing)

label = ['_', num2str(nfeats), 'feats_', num2str(sm), 'sm'];

if ~iscell(methods)
   methods = {methods}; 
end


for j = 1:numel(methods)
    fname = ['saved data/QPFS_res', methods{j}, postfix,'.mat'];
    if exist(fname, 'file')
        res = load(fname);
    else
        continue;
    end
    if ~isfield(res, 'pars')
        fprintf('Regression parameters for %s were not saved \n', fname);
        continue;
    end
    
    ncvs = length(res.pars);
    if isempty(xtest) || isempty(ytest)
        num_obs = size(xtrain, 1);
        idx = linspace(1, num_obs, ncvs);
        time_points = time_points(1:num_obs);
        ncv = ncvs;
        xtest = xtrain(1 + idx(ncvs-1):end, :, :, :);
        xtrain = xtrain(1:idx(ncvs-1), :, :, :);
        ytest = ytrain(1 + idx(ncvs-1):end, :);
        ytrain = ytrain(1:idx(ncvs-1), :);
    else
        mse = read_errors(res.err);
        [~, ncv] = min(mse(:, nfeats));
    end
    active_idx = res.idx_selected{ncv}(:, nfeats);
    w = res.pars{ncv}([true; active_idx == 1], :, nfeats);
    Ntrain = size(xtrain, 1);
    x = [xtrain(Ntrain - ntrain + 1:end, :, :, :); xtest(1:ntest, :, :, :)];
    y = [ytrain(Ntrain - ntrain + 1:end, :); ytest(1:ntest, :)];
    ypred = lmregress(w, select_active_features(x, active_idx));
    plot_xyz_coordinates(time_points(Ntrain - ntrain + 1:Ntrain + ntest), y, ...
        ypred, ntrain, methods{j}, sm, label)
    clear res;
end

end