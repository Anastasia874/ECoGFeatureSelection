function qpfs_feature_analysis(res_fname, expname, nselected)
% plots feature selection results.


if ischar(res_fname)
    % load [err, A, complexity, idx_selected, pars, pvals], returned by
    % QP_feature_selection:
    res_fname = load(res_fname);    
end

% or read them from the struct
if isfield(res_fname, 'A')
    A = res_fname.A;
end
[nfeats, modes] = nfeatures(res_fname);
nchan = modes(1);
nfreqs = modes(2); % first one is the time series

idx_selected = res_fname.idx_selected;
pvals = res_fname.pvals;
params = res_fname.params;
qpfs = res_fname.qpfs;
fr_range = frequency_range(params.frequency_bands);
fr_range = fr_range(1:nfreqs - 1);

if nargin < 3
    nselected = [round(nfeats/2), nfeats];
end

if nargin < 2
    expname = '';
end
name = [expname, '_', params.features];
if isfield(params, 'log') && params.log
    name = [name, '_log'];
end
if isfield(params, 'vel') && params.vel
    name = [name, 'vel'];
end
name = [name, '_', qpfs.sim];
if qpfs.tns_flag
    name = [name, '_', num2str(qpfs.Arank), '_', num2str(qpfs.iters)];
end
                                    




ALPHA = 0.05;
nsel = size(idx_selected{1}, 2);
alphastr = strrep(num2str(ALPHA), '.', 'p');
freqs = zeros(nfeats, nsel);
n_targets = size(pvals{1}, 2);
avpvals = zeros(nfeats, n_targets, nsel);
NCVs = numel(pvals);
complexity = zeros(nsel, NCVs);
for i = 1:NCVs
    freqs = freqs + idx_selected{i};
    nsel = repmat(~idx_selected{i}, 1, 1, n_targets);
    nsel = permute(nsel, [1, 3, 2]);
    avpvals = avpvals + pvals{i}(2:end, :, :) + nsel;
    complexity(:, i) = sum(idx_selected{i});
end

% plot 'significant' features by threshold, x-y-x in one plot:
avpvals = permute(avpvals, [1,3, 2]);
avpvals = avpvals / NCVs;

xx = repmat(1:nfeats, 1, 3);
if length(xx) > 500
    xt = 1:400:length(xx);
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
figname = ['..\fig\qpfs\', name,'sign_features_complexity_xyz_alpha', alphastr];
savefig([figname, '.fig']);
saveas(f, [figname, '.png'])
close(f);

freqs = freqs / NCVs;
freqs_by_feat = mean(freqs, 2);

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
for i = 1:NCVs
    if isfield(res_fname, 'A')
        A{i} = res_fname.A{i};
    elseif iscell(res_fname.ak{i})
        A{i} = a_to_A(res_fname.ak{i});
    else
        A{i} = res_fname.ak{i};
    end
    a = A{i}(:);
    a = sort(a, 'ascend');
    idx = a > 0;
    h = plot(a(idx), flipud(find(idx)), 'k-', 'linewidth', 2);
end
xlabel('Threshold, $\epsilon$', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel('Complexity', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
hold off;
set(gca, 'FontSize', 15, 'FontName', 'Times');
axis tight;
h.Parent.XScale = 'log';
figname = ['..\fig\qpfs\', name,'complexity_threshold'];
savefig([figname, '.fig']);
saveas(f, [figname, '.png'])
close(f);


% find out, which features are the best:
electrodes = 1:nchan;
if nfreqs == length(fr_range) + 1
xfreqs = {'TS'};
xfreqs(2:nfreqs) = arrayfun(@(x) num2str(x), fr_range, 'Uniformoutput', 0);
else
    xfreqs = arrayfun(@(x) num2str(x), fr_range, 'Uniformoutput', 0);
end

freqs_by_feat = reshape(freqs_by_feat, nchan, nfreqs);
f = figure;
imagesc(freqs_by_feat); 
caxis manual
caxis([0 1]); colorbar;
xticks_idx = 1:3:nfreqs;
yticks_idx = 1:2:length(electrodes);
set(gca, 'xtick', xticks_idx)
set(gca, 'xticklabel', xfreqs(xticks_idx));
set(gca, 'ytick', yticks_idx)
set(gca, 'yticklabel', electrodes(yticks_idx));
set(gca, 'FontSize', 15, 'FontName', 'Times');
xlabel('Frequency', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel('Electrode', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
figname = ['..\fig\qpfs\', name,'electrode_by_freq_selection_rate'];
savefig([figname, '.fig']);
saveas(f, [figname, '.png'])
close(f);

% For each frequnecy plot how often each electrode was selected
for fr = 1:nfreqs
    figname = ['..\fig\qpfs\', name,'templ_electrodes_fr', xfreqs{fr}];
    fill_electrodes_template(freqs_by_feat(:, fr), ...
                    ['Frequency = ', xfreqs{fr}], figname);    
end
figname = ['..\fig\qpfs\', name,'templ_electrodes_allfr_max'];
fill_electrodes_template(max(freqs_by_feat, [], 2), 'All frequencies (max)', figname);
figname = ['..\fig\qpfs\', name,'templ_electrodes_allfr_mean'];
fill_electrodes_template(mean(freqs_by_feat, 2), 'All frequencies (mean)', figname);

% Plot max  frequnecy for each electrode on channel template:
figname = ['..\fig\qpfs\', name,'templ_electrodes_maxfr'];
[~, idx] = max(freqs_by_feat(:, 2:end), [], 2);
fill_electrodes_template(fr_range(idx), 'Max frequency', figname);


% 'significant' features, no correction:
dim = 1:n_targets;
if n_targets == 3
dimstr = {'x', 'y', 'z'};
else
dimstr = arrayfun(@(x) num2str(x), dim, 'Uniformoutput', 0);
end
    
for d = dim
    for c = nselected
        figname = ['..\fig\qpfs\', name, 'electrode_by_freq_selection_rate_', num2str(c), ...
                '_sign_alpha', alphastr, '_', dimstr{d}];
        plot_significant_features_by_complexity(c, d, nchan, nfreqs, length(A), ...
                                         complexity, pvals, ...
                                         idx_selected, ALPHA, 1, figname, xfreqs);
    end
end

% 'significant' features, Bonferoni correction:
for d = dim
    for c = nselected
        figname = ['..\fig\qpfs\', name, 'electrode_by_freq_selection_rate_', num2str(c), ...
                '_sign_bc_alpha', alphastr, '_', dimstr{d}];
        plot_significant_features_by_complexity(c, d, nchan, nfreqs, length(A), ...
                                         complexity, pvals, ...
                                         idx_selected, ALPHA, c, figname, xfreqs);
    end
end
% idxlist = 1:nfeats;
% [i, j, k] = ind2sub(size(A{1}), idxlist);
% freqs_selections = zeros(legnth(electrodes), nfreqs);

% err = cat(1, err{:});
% [mse, crr] = read_errors(err);


end