function rank_results(res_struct)

if ischar(res_struct)
    res_struct = load(res_struct);  
elseif iscell(res_struct)
    for rf = 1:numel(res_struct)
        res(rf) = load(res_struct{rf});        
    end
    res_struct.tns_err = [res().tns_err];
    res_struct.experiments = [res().experiments];
    res_struct.tns_err = [res().tns_err];
    res_struct.mat_err = [res().mat_err];
    res_struct.mat_pls_err = [res().mat_pls_err];
    res_struct.tns_pls_err = [res().tns_pls_err];
    res_struct.ncomp_to_try = res(1).ncomp_to_try;
end

tns_err = res_struct.tns_err;
mat_err = res_struct.mat_err;
tns_pls_err = res_struct.tns_pls_err;
mat_pls_err = res_struct.mat_pls_err;

res = {tns_err, mat_err, tns_pls_err, mat_pls_err};
alg_names = {'QPFS', 'NQPFS', 'PLS', 'NPLS'};
feats_range = res_struct.ncomp_to_try;
experiments = res_struct.experiments;
nfeats = length(feats_range);

% average results by nfeats:
nmethods = numel(res);
nexp = numel(experiments);
mse = cell(1, nmethods); crr = mse; dtwd = mse; made = mse; crr_ho = mse;
for i = 1:nexp
    for j = 1:nmethods
        [mse{i, j}, crr{i, j}, dtwd{i, j}, ~, ~, ~, crr_ho{i, j}, made{i, j}] = ...
                                                   read_nnan_errors(res{j}{i});

        if size(mse{i, j}, 1) < 5
            ns = size(mse{i, j}, 1);
            mse{i, j}(ns + 1:5, 1:nfeats) = NaN(5 - ns, nfeats);
            crr{i, j}(ns + 1:5, 1:nfeats) = NaN(5 - ns, nfeats); 
            dtwd{i, j}(ns + 1:5, 1:nfeats) = NaN(5 - ns, nfeats);
            made{i, j}(ns + 1:5, 1:nfeats) = NaN(5 - ns, nfeats);
            crr_ho{i, j}(ns + 1:5, 1:nfeats) = NaN(5 - ns, nfeats);
        end
    end
end

for nf = 1:nfeats
    for j = 1:nmethods
        tmp = cell2mat(mse(:, j));
        tmp_mse(j, :) = tmp(:, nf);
        tmp = cell2mat(crr(:, j));
        tmp_crr(j, :) = tmp(:, nf);
        tmp = cell2mat(dtwd(:, j));
        tmp_dtwd(j, :) = tmp(:, nf);
        tmp = cell2mat(made(:, j));
        tmp_made(j, :) = abs(tmp(:, nf));
    end
    for i = 1:size(tmp_mse, 2)
    [~, ~, idxmse(:, i)] = unique(tmp_mse(:, i));
    [~, ~, idxcrr(:, i)] = unique(-tmp_crr(:, i));
    [~, ~, idxdtwd(:, i)] = unique(tmp_dtwd(:, i));
    [~, ~, idxmade(:, i)] = unique(tmp_made(:,i));
    end
    rank_mse(:, nf) = mean(idxmse, 2);
    rank_crr(:, nf) = mean(idxcrr, 2);
    rank_dtwd(:, nf) = mean(idxdtwd, 2);
    rank_made(:, nf) = mean(idxmade, 2);
end


for j = 1:nmethods
    mean_mse(j, :) = nanmean(cell2mat(mse(:, j)));
    mean_crr(j, :) = nanmean(cell2mat(crr(:, j)));   
    mean_dtwd(j, :) = nanmean(cell2mat(dtwd(:, j)));
    mean_crrho(j, :) = nanmean(cell2mat(crr_ho(:, j)));
    mean_made(j, :) = nanmean(abs(cell2mat(made(:, j))));
end

lgnd = arrayfun(@(x) num2str(x), feats_range, 'UniformOutput', 0);
metric_names = {'MSE', 'Correlation', 'DTWD', 'MADE'};
plot_rankings({rank_mse, rank_crr, rank_dtwd, rank_made}, metric_names, ...
                                        {}, alg_names, 'Rank', 1)
plot_rankings({mean_mse, mean_crr, mean_dtwd, mean_made}, metric_names, ...
                                        lgnd, alg_names, '', 0)
end


function [mse, crr, dtwd, mse_train, crr_train, dtwd_train, crr_ho, ...
                                     made, made_train] = read_nnan_errors(err)

[mse, crr, dtwd, mse_train, crr_train, dtwd_train, crr_ho, ...
                                     made, made_train] = read_errors(err);

idx = ~isnan(nanmean(mse));
mse = mse(:, idx);
idx = ~isnan(nanmean(mse_train));
mse_train = mse_train(:, idx);

idx = ~isnan(nanmean(crr));
crr = crr(:, idx);
idx = ~isnan(nanmean(crr_train));
crr_train = crr_train(:, idx);
idx = ~isnan(nanmean(crr_ho{1}));
crr_ho = crr_ho{1}(:, idx);

idx = ~isnan(nanmean(dtwd));
dtwd = dtwd(:, idx);
idx = ~isnan(nanmean(dtwd_train));
dtwd_train = dtwd_train(:, idx);

idx = ~isnan(nanmean(made));
made = made(:, idx);
idx = ~isnan(nanmean(made_train));
made_train = made_train(:, idx);

end

function plot_rankings(metrics, mnames, lgnd, alg_names, ytxt, title_flag)

nsubfig = numel(metrics);
ncols = round(sqrt(nsubfig));
nrows = ceil(nsubfig / ncols);

figure;
for i = 1:nsubfig
    h(i) = subplot(nrows, ncols, i);  
    bar(metrics{i})
    set(gca, 'xtick', 1:4);
    set(gca, 'xticklabel', alg_names);
    xlabel([], 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
    if ~title_flag
        ylabel(mnames{i}, 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
    end
    set(gca, 'FontSize', 12, 'FontName', 'Times');
    axis tight;
    if title_flag
        title(mnames{i})
    end
end

% subplot(2,2,2)       
% bar(mean_crr)   
% set(gca, 'xtick', 1:4);
% set(gca, 'xticklabel', alg_names);
% xlabel([], 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
% % ylabel('Correlation', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
% set(gca, 'FontSize', 12, 'FontName', 'Times');
% axis tight;
% title('Correlation')
% 
% h2 = subplot(2,2,3);       
% bar(mean_dtwd)   
% set(gca, 'xtick', 1:4);
% set(gca, 'xticklabel', alg_names);
% xlabel([], 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
% % ylabel('DTW', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
% set(gca, 'FontSize', 12, 'FontName', 'Times');
% axis tight;
% title('DTW')
% 
% subplot(2,2,4)       
% bar(mean_made)   
% set(gca, 'xtick', 1:4);
% set(gca, 'xticklabel', alg_names);
% xlabel([], 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
% % ylabel('MADE', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
% set(gca, 'FontSize', 12, 'FontName', 'Times');
% axis tight;
% title('MADE')

if ~isempty(lgnd)
legend(lgnd, ...
    'orientation', 'horizontal', ...
    'location', 'north', 'fontname', 'Times', 'fontsize', 12, 'Interpreter', 'latex');
end

if title_flag
p1 = get(h(1),'position');
p2 = get(h(1 + ncols),'position');
height = p1(2)+p1(4)-p2(2);
axes('position',[p2(1) p2(2) p2(3) height],'visible','off');
ylabel(ytxt,'visible','on', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
end

end