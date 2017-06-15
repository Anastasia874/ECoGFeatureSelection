function plot_matrix(scalo, x, y, xtxt, ytxt, title_txt, figname, folder, clb_limits)

if ~exist('clb_limits', 'var')
    clb_limits = [];
end


f = figure;
imagesc(scalo);
if ~isempty(clb_limits)
    caxis manual
    caxis(clb_limits);
end
colorbar;
title(title_txt);
xlabel(xtxt, 'FontSize', 18, 'FontName', 'Times', 'Interpreter','latex');
ylabel(ytxt, 'FontSize', 18, 'FontName', 'Times', 'Interpreter','latex');
nstep = calc_step(size(scalo, 2), 9);
xticks_idx = 1:nstep:size(scalo, 2);
nstep = calc_step(size(scalo, 1), 16);
yticks_idx = 1:nstep:size(scalo, 1);
set(gca, 'xtick', xticks_idx)
set(gca, 'xticklabel', x(xticks_idx));
set(gca, 'ytick', yticks_idx)
set(gca, 'yticklabel', y(yticks_idx));
set(gca, 'FontSize', 15, 'FontName', 'Times');

figname = fullfile(folder, figname);
savefig([figname, '.fig']);
saveas(f, [figname, '.png'])
close(f);



end

function step = calc_step(allpoints, npoints)

% nsteps = round(allpoints / (npoints - 1));
step = round((allpoints - 1) / (npoints - 1));

end