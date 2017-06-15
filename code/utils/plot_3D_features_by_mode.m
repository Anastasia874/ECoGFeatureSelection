function plot_3D_features_by_mode(freqs_by_feat, mode, values, name, ...
                                    txt, labels)

x_ticks = values{mode(2)};
y_ticks = values{mode(1)}; 
title_var = values{mode(3)};         
title_txt = labels{mode(3)};
x_label = labels{mode(2)};
y_label = labels{mode(1)};
folder = '..\fig\qpfs\';

freqs_by_feat = permute(freqs_by_feat, mode);
ntbins = size(freqs_by_feat, 3);

for i = 1:ntbins
    
figname = [name, 'electrode_by_freq_selection_rate', txt, num2str(i)];
plot_matrix(freqs_by_feat(:, :, i), x_ticks, y_ticks, x_label, y_label, ...
    [title_txt, ' ', num2str(title_var(i))], figname, folder, [0, 1]);

end


end

% f = figure;
% imagesc(freqs_by_feat(:, :, i)); 
% caxis manual
% caxis([0 1]);
% colorbar;
% xticks_idx = 1:3:size(freqs_by_feat, 2);
% yticks_idx = 1:2:size(freqs_by_feat, 1);
% set(gca, 'xtick', xticks_idx)
% set(gca, 'xticklabel', x_ticks(xticks_idx));
% set(gca, 'ytick', yticks_idx)
% set(gca, 'yticklabel', y_ticks(yticks_idx));
% set(gca, 'FontSize', 15, 'FontName', 'Times');
% xlabel(x_label, 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
% ylabel(y_label, 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
% title([title_txt, ' ', num2str(title_var(i))]);
% figname = ['..\fig\qpfs\', name, 'electrode_by_freq_selection_rate', txt, ...
%                                                             num2str(i)];
% savefig([figname, '.fig']);
% saveas(f, [figname, '.png'])
% close(f);