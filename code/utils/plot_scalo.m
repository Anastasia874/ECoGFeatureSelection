function plot_scalo(scalo, time, frequency_bands, title_txt, figname, folder)


[fr_range, ~, ~] = frequency_range(frequency_bands);

f = figure;
imagesc(scalo);
colorbar;

title(title_txt);
xlabel('Time bins', 'FontSize', 18, 'FontName', 'Times', 'Interpreter','latex');
ylabel('Frequency bins', 'FontSize', 18, 'FontName', 'Times', 'Interpreter','latex');
xticks_idx = 1:1000:length(time);
set(gca, 'xtick', xticks_idx)
set(gca, 'xticklabel', time(xticks_idx));
yticks_idx = 1:6:length(fr_range);
set(gca, 'ytick', yticks_idx)
set(gca, 'yticklabel', fr_range(yticks_idx));
set(gca, 'FontSize', 15, 'FontName', 'Times');

figname = fullfile(folder, figname);
savefig([figname, '.fig']);
saveas(f, [figname, '.png'])
close(f);

end