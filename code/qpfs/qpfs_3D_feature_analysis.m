function qpfs_3D_feature_analysis(res_fname, nselected)
% plots feature selection results.

% Results structure for 3D features contains the following fields (each
% contains a [1 x nbatches] cell array, where each cell corresponds to a 
% batch. All cells have the same structure, described below):
% err - {ncv x nfeatures} with error structures. Complexities that were not
%       eveluated are filled with nans
% idx_selected - {1 x ncv} cell with arrays [nfeatures x nevals] matrices. 
%          Each matrix contains indices of selected features by evaluations
% pars - {1 x ncv} cell with arrays [(nfeatures + 1)x nydim x nevals] matrices. 
%         Each (:, i, j)-th fiber stores regression parameters for i-th y 
%         dimension and j-th evaluation (i.e., when complexity equals j). 
%         The first value is the intercept. 
% pvals - same as pars, but contains pvalues for t-test of regression 
%         parameters VS zeros
% ak    - (for tns results) {1 x ncv} cell array, each cell contains {1 x 3} 
%         with matrices [R x n_d], 
%         where R is the number of cimponents in low-rank decomposition of
%         A. These matrices comprise feature selection variable A (see a_to_A)
%         (for matrix results) {1 x ncv} cell array, each cell contains  
%         a column [nfeats x 1] equal to A(:) 
% qpfs  - structure with QPFS parameters
% params - structure with feature extruction parameters

if ischar(res_fname)
    % load [err, A, complexity, idx_selected, pars, pvals], returned by
    % QP_feature_selection:
    load(res_fname);    
else
    % or read them from the struct
    ak = res_fname.ak;
    idx_selected = res_fname.idx_selected;
%     complexity = res_fname.complexity;
    pvals = res_fname.pvals;
    qpfs = res_fname.qpfs;
    params = res_fname.params;
end

name = [params.features, '_', qpfs.sim, '_', num2str(qpfs.Arank), ...
                                        '_', num2str(qpfs.iters)];
ntbins = params.modes(1); nfreqs = params.modes(2);
nchan = params.modes(3); 
fr_bands = params.frequency_bands;
fr_range = frequency_range(fr_bands);
fr_range = fr_range(1:nfreqs);


if nargin < 2
    nselected = [100, 500, 1000];
end



nfeats = nchan * nfreqs * ntbins;
NCVs = length(pvals{1});
% idx_feat = reshape_2D_matfeatures(1:nfeats, 32, 26);
% idx_feat = idx_feat(:);
% idx_f2 = [1; 1 + idx_feat(:)];


ALPHA = 0.05;
alphastr = strrep(num2str(ALPHA), '.', 'p');
n_targets = size(pvals{1}{1}, 2);
nbatches = numel(ak);
nevals = size(idx_selected{1}{1}, 2);
selfreqs = zeros(nfeats, nevals, nbatches);
for nb = 1:nbatches
    
nameb = [name, '_batch', num2str(nb)];
% !!! the following is only needed for when ak was not saved for all cv splits
% fix this later 
A = cell(1, NCVs);

if qpfs.tns_flag
    for ncv = 1:NCVs    
        A{ncv} = a_to_A(ak{nb}{ncv});
    end
else
    for ncv = 1:NCVs
        A{ncv} = reshape(ak{nb}{ncv}, ntbins, nfreqs, nchan);
    end
end



avpvals = zeros(nfeats, n_targets, nevals);
for i = 1:length(A)
%     A{i} = A{i}(idx_feat);
%     idx_selected{i} = idx_selected{i}(idx_feat, :);
%     pvals{i} = pvals{i}(idx_f2, :, :);
%     pars{i} = pars{i}(idx_f2, :, :);
    
    selfreqs(:, :, nb) = selfreqs(:, :, nb) + idx_selected{nb}{i};
    nsel = repmat(~idx_selected{nb}{i}, 1, 1, n_targets);
    nsel = permute(nsel, [1, 3, 2]);
    avpvals = avpvals + pvals{nb}{i}(2:end, :, :) + nsel;
end

% plot 'significant' features by threshold, x-y-x in one plot:
avpvals = permute(avpvals, [1, 3, 2]);
avpvals = avpvals / NCVs;

xx = repmat(1:nfeats, 1, 3);
if length(xx) > 500
    xt = 1:300:length(xx);
else
    xt = 1:5:length(xx);
end

f = figure;
colormap(f, gray);
imagesc(reshape(avpvals, nfeats, []) < ALPHA);
set(gca, 'xtick', xt);
set(gca, 'xticklabel', xx(xt));
xlabel('Complexity', 'FontSize', 18, 'FontName', 'Times', 'Interpreter','latex');
ylabel('Features', 'FontSize', 18, 'FontName', 'Times', 'Interpreter','latex');
set(gca, 'FontSize', 15, 'FontName', 'Times');
title(['Batch ', num2str(nb)]);
figname = ['..\fig\qpfs\', nameb, 'sign_features_complexity_xyz_alpha', alphastr];
savefig([figname, '.fig']);
saveas(f, [figname, '.png'])
close(f);

selfreqs(:, :, nb) = selfreqs(:, :, nb) / length(A);
freqs_by_feat = mean(selfreqs(:, :, nb), 2);

% figure;
% imagesc(freqs); colorbar;
% xlabel('Complexity', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
% ylabel('Features');
% hold off;
% set(gca, 'FontSize', 15, 'FontName', 'Times');
% axis tight;

% figure;
% plot(mean(freqs, 2), 'k', 'linewidth', 2);
% xlabel('Feature combinations $(i,j,k)$', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
% ylabel('Selection frequency');
% hold off;
% set(gca, 'FontSize', 15, 'FontName', 'Times');
% axis tight;

f = figure; hold on
for i = 1:numel(A)
    a = A{i}(:);
    a = sort(a, 'ascend');
    idx = a > 0;
    h = plot(a(idx), flipud(find(idx)), 'k-', 'linewidth', 2);
end
xlabel('Threshold $\epsilon$', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel('Complexity', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
hold off;
set(gca, 'FontSize', 15, 'FontName', 'Times');
h.Parent.XScale = 'log';
axis tight;
title(['Batch ', num2str(nb)]);
figname = ['..\fig\qpfs\', nameb,'complexity_threshold'];
savefig([figname, '.fig']);
saveas(f, [figname, '.png'])
close(f);


% % find out, which features are the best:
electrodes = 1:nchan;
freqs_by_feat = reshape(freqs_by_feat, ntbins, nfreqs, nchan);
% plot_3D_features_by_mode(freqs_by_feat, [3, 2, 1], {1:ntbins, fr_range, electrodes}, nameb, ...
%                        '_tbins', {'Time bin', 'Frequency', 'Electrodes'});
% % plot_3D_features_by_mode(freqs_by_feat, [3, 1, 2], {1:ntbins, fr_range, electrodes}, name, ...
% %                         '_freqs', {'Time bin', 'Frequency', 'Electrodes'});
% % plot_3D_features_by_mode(freqs_by_feat, [2, 1, 3], {1:ntbins, fr_range, electrodes}, name, ...
% %                         '_elec',{'Time bin', 'Frequency', 'Electrodes'});


% For each frequnecy plot how often each electrode was selected
for t = 1:ntbins
figname = ['..\fig\qpfs\', nameb,'templ_electrodes_allfr_max', '_t', num2str(t)];
fill_electrodes_template(max(squeeze(freqs_by_feat(t, :, :))), ['All frequencies (max), batch ', num2str(nb)], figname);
figname = ['..\fig\qpfs\', nameb,'templ_electrodes_allfr_mean', '_t', num2str(t)];
fill_electrodes_template(mean(squeeze(freqs_by_feat(t, :, :))), ['All frequencies (mean), batch ', num2str(nb)], figname);
% Plot max  frequnecy for each electrode on channel template:
figname = ['..\fig\qpfs\', nameb,'templ_electrodes_maxfr', '_t', num2str(t)];
[~, idx] = max(squeeze(freqs_by_feat(t, :, :)));
fill_electrodes_template(fr_range(idx), ['Max frequency, batch ', num2str(nb)], figname);
end

for fr = 1:length(fr_range)
figname = ['..\fig\qpfs\', nameb,'templ_electrodes_allt_max', '_fr', num2str(fr_range(fr))];
fill_electrodes_template(max(squeeze(freqs_by_feat(:, fr, :))), ['All frequencies (max), batch ', num2str(nb)], figname);
figname = ['..\fig\qpfs\', nameb,'templ_electrodes_allt_mean', '_fr', num2str(fr_range(fr))];
fill_electrodes_template(mean(squeeze(freqs_by_feat(:, fr, :))), ['All frequencies (mean), batch ', num2str(nb)], figname);
% Plot max  frequnecy for each electrode on channel template:
figname = ['..\fig\qpfs\', nameb,'templ_electrodes_maxt', '_fr', num2str(fr_range(fr))];
[~, idx] = max(squeeze(freqs_by_feat(:, fr, :)));
fill_electrodes_template(fr_range(idx), ['Max frequency, batch ', num2str(nb)], figname);   
end






% % 'significant' features, no correction:
% dim = 1:n_targets;
% if n_targets == 3
% dimstr = {'x', 'y', 'z'};
% else
% dimstr = arrayfun(@(x) num2str(x), dim, 'Uniformoutput', 0);
% end
%     
% for d = dim
%     for c = nselected
%         figname = [nameb, 'electrode_by_freq_selection_rate_', num2str(c), ...
%                 '_sign_alpha', alphastr, '_', dimstr{d}];
%         plot_significant_features_by_complexity_3D(c, d, nchan, nfreqs, ntbins, length(A), ...
%                                          pvals{nb},idx_selected{nb}, ...
%                                          ALPHA, 1, figname, ...
%                                          fr_range);
%     end
% end
% 
% % 'significant' features, Bonferoni correction:
% for d = dim
%     for c = nselected
%         figname = [nameb, 'electrode_by_freq_selection_rate_', num2str(c), ...
%                 '_sign_bc_alpha', alphastr, '_', dimstr{d}];
%         plot_significant_features_by_complexity_3D(c, d, nchan, nfreqs, ntbins, length(A), ...
%                                                  pvals{nb},idx_selected{nb}, ...
%                                                  ALPHA, c, figname, ...
%                                                  fr_range);
%     end
% end

end

end


