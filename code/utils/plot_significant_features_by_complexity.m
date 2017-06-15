function plot_significant_features_by_complexity(c, d, nchan, nfreqs, niters, complexity, pvals, ...
                                              idx_selected, alpha, corrctn, figname, xfreqs)

electrodes = 1:nchan;
sign_freqs = zeros(nchan*nfreqs, niters);
for i = 1:niters
    if ~ismember(c, complexity(:, i))
        sign_freqs(:, i) = NaN(nchan * nfreqs, 1);
        continue;
    end
    sign_freqs(:, i) = (pvals{1}(2:end, d, complexity(:, i) == c) + ...
                        ~idx_selected{i}(:, complexity(:, i) == c))< alpha/corrctn;
end

sign_freqs = reshape(nanmean(sign_freqs, 2), nchan, nfreqs);
f = figure;
imagesc(sign_freqs);
caxis manual
caxis([0 1]); colorbar;
xticks_idx = 1:3:nfreqs;
yticks_idx = 1:2:nchan;
set(gca, 'xtick', xticks_idx)
set(gca, 'xticklabel', xfreqs(xticks_idx));
set(gca, 'ytick', yticks_idx)
set(gca, 'yticklabel', electrodes(yticks_idx));
set(gca, 'FontSize', 15, 'FontName', 'Times');
xlabel('Frequency', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel('Electrode', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
savefig([figname, '.fig']);
saveas(f, [figname, '.png'])
close(f);



end