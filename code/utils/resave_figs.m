function resave_figs

folder = '../fig/initial_exploration/corrs_by_freq/';
pattern = 'LW*';
figures = dir(fullfile(folder, [pattern, '.fig']));

fs = 100;
frequency_bands = [1.5, 4, 0.1; 4, 8, 0.5; 8, 14, 1; ...
                    14, 20, 1; 20, 30, 1; 30, 50, 1; ...
                    50, 90, 2; 90, 100, 1; ];
                
frequency_bands = frequency_bands(frequency_bands(:, 2) < 0.5 * fs, :);                
[fr_range, ~, fnj] = frequency_range(frequency_bands);

xtcks = fnj;
xtcks(2:end) = xtcks(2:end) - 1;

for i = 1:length(figures)
    fig = open([folder, figures(i).name]);
    ylabel('Electrodes', 'FontSize', 18, 'FontName', 'Times', 'Interpreter','latex');
    xlabel('Frequency', 'FontSize', 18, 'FontName', 'Times', 'Interpreter','latex');
    set(gca, 'xtick', xtcks)
    set(gca, 'xticklabel', fr_range(xtcks));
    figname = figures(i).name(1:end-4);
    savefig([folder, figname, '.fig']);
    saveas(fig, [folder, figname, '.png'])
    close(fig);
end



end