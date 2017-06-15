function plot_significant_features_by_complexity_3D(c, d, nchan, nfreqs, ntbins, ...
                                              niters, pvals, idx_selected, ...
                                              alpha, corrctn, ...
                                              figname, fr_range)


sign_freqs = zeros(nchan*nfreqs*ntbins, niters);
for i = 1:niters
    sign_freqs(:, i) = (pvals{1}(2:end, d, c) + ...
                        ~idx_selected{i}(:, c))< alpha/corrctn;
end

electrodes = 1:nchan;
freqs_by_feat = reshape(mean(sign_freqs, 2), ntbins, nfreqs, nchan);
plot_3D_features_by_mode(freqs_by_feat, [3, 2, 1], {1:ntbins, fr_range, electrodes}, figname, ...
                       '_tbins', {'Time bin', 'Frequency', 'Electrodes'});
plot_3D_features_by_mode(freqs_by_feat, [3, 1, 2], {1:ntbins, fr_range, electrodes}, figname, ...
                        '_freqs', {'Time bin', 'Frequency', 'Electrodes'});
plot_3D_features_by_mode(freqs_by_feat, [2, 1, 3], {1:ntbins, fr_range, electrodes}, figname, ...
                        '_elec',{'Time bin', 'Frequency', 'Electrodes'});


end