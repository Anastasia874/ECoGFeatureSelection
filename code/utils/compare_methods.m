function compare_methods(features, methods, postfix, date1, date2, folder, labels)

if ~iscell(features)
    features = {features, features};
end

if ~iscell(methods)
   methods = {methods, methods}; 
end

if ~iscell(postfix)
    name_postfix = postfix;
    postfix = {postfix, postfix};
else
    name_postfix = [postfix{1}, '_', postfix{2}];
end


mat_fname = ['saved data/QPFS_res', features{1}, '_', methods{1}, postfix{1},'.mat'];
mat_res = load(mat_fname);
err = padd_error_struct(mat_res.err, 2);
[mqp_mse, mqp_crr, mqp_dtw, mqp_mse_train, mqp_crr_train, mqp_dtw_train, ...
                    mqp_crr_ho, mqp_made, mqp_made_train] = read_errors(err);
nfeats = nfeatures(mat_res);
clear mat_res;

tns_fname = ['saved data/QPFS_res', features{2}, '_', methods{2}, postfix{2},'.mat'];
tns_res = load(tns_fname);

err = padd_error_struct(tns_res.err, 2);
if ~exist('qp_mse', 'var')
[qp_mse, qp_crr, qp_dtw, qp_mse_train, qp_crr_train, qp_dtw_train, qp_crr_ho, ...
                         qp_made, qp_made_train] = read_errors(err);
end
nfeats = max([nfeats, nfeatures(tns_res)]);
clear tns_res;

name_postfix = [features{1}, '_', methods{1}, '_to_', features{2}, '_', ...
                    methods{2}, '_', name_postfix];
legend_txt = {[date1, ' train(cv) ', labels{2}], [date1, ' test(cv) ', labels{2}], ...
              [date1, ' train(cv) ', labels{1}], [date1, ' test(cv) ', labels{1}]};
legend_txt_ho = {[date1, ' train(cv) ', labels{2}], [date1, ' test(cv) ', labels{2}], ...
              [date1, ' HO ', labels{2}],...
              [date1, ' train(cv) ', labels{1}], [date1, ' test(cv) ', labels{1}],...
              [date1, ' HO ', labels{1}]};

plot_cv_results_area2_nan({ {qp_crr_train, qp_crr}, {mqp_crr_train, mqp_crr} }, ...
                      1:nfeats, 'Correlation coef', 'Number of features', ...
                       legend_txt, ...
                       [folder, 'corr_QPFS_nfeats_', name_postfix], ...
                       {'-', '--'}, 'none');      
if ~isempty(date2)                 
plot_cv_results_area2_nan({qp_crr_train, qp_crr, ...
                           mqp_crr_train, mqp_crr, ...
                           qp_crr_ho{2}, mqp_crr_ho{2}}, ...
                      1:nfeats, 'Correlation coef', 'Number of features', ...
                       [legend_txt, ...
                       {[date2, ' ', labels{2}], [date2, ' ', labels{1}]}], ...
                       [folder, 'corr_ho2_QPFS_nfeats_', name_postfix], ...
                       '-', 'none');
end

plot_cv_results_area2_nan({ {qp_crr_train, qp_crr, qp_crr_ho{1}}, ...
                           {mqp_crr_train, mqp_crr, mqp_crr_ho{1}} }, ...
                      1:nfeats, 'Correlation coef', 'Number of features', ...
                       legend_txt_ho, ...
                       [folder, 'corr_ho_QPFS_nfeats_', name_postfix], ...
                       {'-', '--', ':'}, 'none');
    
                   
plot_cv_results_area2_nan({ {qp_mse_train, qp_mse}, ...
                           {mqp_mse_train, mqp_mse} }, ...
                      1:nfeats, 'Scaled MSE', 'Number of features', ...
                       legend_txt, ...
                       [folder, 'mse_QPFS_nfeats_', name_postfix], ...
                       {'-', '--'}, 'none'); 
                   
plot_cv_results_area2_nan({ {qp_dtw_train, qp_dtw}, ...
                           {mqp_dtw_train, mqp_dtw} }, ...
                      1:nfeats, 'DTW', 'Number of features', ...
                       legend_txt, ...
                       [folder, 'dtw_QPFS_nfeats_', name_postfix], ...
                       {'-', '--'}, 'none'); 
                   

plot_cv_results_area2_nan({ {qp_made_train, qp_made}, ...
                           {mqp_made_train, mqp_made} }, ...
                      1:nfeats, 'MADE', 'Number of features', ...
                       legend_txt, ...
                       [folder, 'made_QPFS_nfeats_', name_postfix], ...
                       {'-', '--'}, 'none'); 
                   
end