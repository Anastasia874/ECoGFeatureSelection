function read_batch_errors(err, figname)
% Read errors, outputed by batch QPFS for 3D dataset and plot all batches 
% for each metric  

if nargin < 1
res = load('saved data/QPFS_res3D_correl_lwrxyz_0p05_frscale_5_nfolds_3_A_ZenasChao_csv_ECoG32-Motion10.mat');
err = res.err;
clear res;
end

nbatches = numel(err);
for nb = 1:nbatches
    if isempty(err{nb})
        continue;
    end
   [mse{nb}, crr{nb}, dtwd{nb}, mse_train{nb}, crr_train{nb}, dtwd_train{nb}, ...
       crr_ho{nb}, made{nb}, made_train{nb}] = read_errors(err{nb});
   
end
plot_train_test_batches({mse, mse_train}, 'Scaled MSE', ['mse_', figname]);
plot_train_test_batches({crr, crr_train, crr_ho}, 'Correlation coef.', ['corr_', figname]);
plot_train_test_batches({dtwd, dtwd_train}, 'DTW', ['dtw_', figname]);
plot_train_test_batches({made, made_train}, 'MADE', ['made_', figname]);




end

function plot_train_test_batches(data, ytext, figname)

colors = get(0,'DefaultAxesColorOrder');

nbatches = numel(data{1});
nbs = find(cellfun(@(x) ~isempty(x), data{1}(:)));

f = figure; hold on;
lgnd2 = {};
if numel(data) > 2
    lgnd1 = {'Test', 'Train', ['HO, batch ', num2str(nbs(1))]};
else
    lgnd1 = {'Test', ['Train, batch ', num2str(nbs(1))]};
end

for nb = 1:nbatches
    if isempty(data{1}{nb})
        lgnd2{end + 1} = ['batch ', num2str(nb)];
        continue;
    end

   idx = find(~isnan(nanmean(data{1}{nb})));
   h(nb) = plot(idx, mean(data{1}{nb}(:, idx)), '--', 'linewidth', 2);
   h1(nb) = plot(idx, mean(data{2}{nb}(:, idx)), '-', 'linewidth', 2);
   if numel(data) > 2
       h2(nb) = plot(idx, mean(data{3}{nb}{1}(:, idx)), ':', 'linewidth', 2);
       h2(nb).Color = colors(nb, :);  
   end
   lgnd2{end + 1} = ['batch ', num2str(nb)];
   h(nb).Color = colors(nb, :);  
   h1(nb).Color = colors(nb, :);  
end
xlabel('Number of features', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel(ytext, 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
set(gca, 'FontSize', 15, 'FontName', 'Times');
if numel(data) > 2
    legend([h(nbs(1)), h1(nbs(1)), h2(nbs(1))], lgnd1, 'location', 'north', ...
        'orientation', 'horizontal','fontname', 'Times', 'fontsize', 15);
else
    legend([h(nbs(1)), h1(nbs(1))], lgnd1, 'location', 'north', 'orientation',...
        'horizontal','fontname', 'Times', 'fontsize', 15);
end
if length(nbs) > 1
    ah=axes('position',get(gca,'position'), 'visible','off');
    legend(ah, h1(nbs(2:end)), lgnd2(nbs(2:end)), 'location', 'southwest', ...
        'fontname', 'Times', 'fontsize', 15);
end
axis tight;

if ~isdir('../fig/batch_qpfs/')
    mkdir('../fig/batch_qpfs/');
end

savefig(['../fig/batch_qpfs/', figname,'.fig']);
saveas(f, ['../fig/batch_qpfs/', figname,'.png']);
close(f);


end