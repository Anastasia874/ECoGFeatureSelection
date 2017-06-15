function err = recompute_errors(res_fname, X, y, X_holdout, y_holdout)
                             
                             
% res_fname = 'saved data/QPFS_res2D_Tucker_1_1_lwrxyz_0p05_frscale_5_nfolds_5_A_ZenasChao_csv_ECoG32-Motion12.mat';                             
load(res_fname);                             
ncvs = length(A);  

m = size(X, 1);
idx_splits = round(linspace(0, m, ncvs + 1));
shuffled_idx = randperm(m);

for cv = 1:ncvs  
    tic
    fprintf('Recompute errors, iteration %i / %i \n', cv, ncvs);
    idx_cv = ismember(shuffled_idx, idx_splits(cv)+1:idx_splits(cv + 1));
    X_train = X(~idx_cv, :, :); X_test = X(idx_cv, :, :);
    y_train = y(~idx_cv, :); y_test = y(idx_cv, :, :);
    for c = complexity(:, cv)'
        active_idx = idx_selected{cv}(:, complexity(:, cv) == c) == 1;
        w = pars{cv}([1; active_idx] == 1, :, complexity(:, cv) == c);
        err{cv, c} = error_struct(@(x) lmregress(w, ...
                                    select_active_features(x, active_idx)),...
                                    X_train, y_train, ...
                                    X_test, y_test, X_holdout, y_holdout);
    end
    toc
end               
    
% save(res_fname, 'err', 'A', 'complexity', 'idx_selected', 'pars', 'pvals');

end