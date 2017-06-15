function plot_significant_features_by_complexity_all(res_fname, compl_range, folder)

res_fname = 'saved data/QPFS_res2D_Tucker_1_1_lwrxyz_0p05_frscale_5_nfolds_5_A_ZenasChao_csv_ECoG32-Motion12.mat';
folder = 'elec_by_freq_sign/';
name = '2D_Tucker_1_1';

load(res_fname);
compl_range = 1:10:numel(A{1});
nchan = 32;
nfreqs = numel(A{1})/nchan;

frequency_bands = [0.5, 3.5, 0.5; 4, 8, 0.5; ... %9, 13, 2; ...
                    9, 18, 3; 20, 45, 5; ...
                    50, 100, 10; ];         
fr_range = frequency_range(frequency_bands);
fr_range = fr_range(1:nfreqs-1);
xfreqs = {'TS'};
xfreqs(2:nfreqs) = arrayfun(@(x) num2str(x), fr_range, 'Uniformoutput', 0);

% 'significant' features, no correction:
nselected = compl_range;

ALPHA = 0.05;
alphastr = strrep(num2str(ALPHA), '.', 'p');
dim = [1, 2, 3];
dimstr = {'x', 'y', 'z'};
for d = dim
    for c = nselected
        figname = ['..\fig\qpfs\', folder,  name, 'electrode_by_freq_selection_rate_', num2str(c), ...
                '_sign_alpha', alphastr, '_', dimstr{d}];
        plot_significant_features_by_complexity(c, d, nchan, nfreqs, length(A), ...
                                         complexity, pvals, ...
                                         idx_selected, ALPHA, 1, figname, xfreqs);
    end
end

% 'significant' features, Bonferoni correction:
for d = dim
    for c = nselected
        figname = ['..\fig\qpfs\', folder, name, 'electrode_by_freq_selection_rate_', num2str(c), ...
                '_sign_bc_alpha', alphastr, '_', dimstr{d}];
        plot_significant_features_by_complexity(c, d, nchan, nfreqs, length(A), ...
                                         complexity, pvals, ...
                                         idx_selected, ALPHA, c, figname, xfreqs);
    end
end



end