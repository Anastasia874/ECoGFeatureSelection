function plot_cv_results_area2_nan(vals, x_vals, ytext, xtext, ...
                                         legend_text, name, specs, markers)

                           
ALPHA = 0.2;                   
if nargin < 5
    legend_text = {'Train', 'Test'};
end
if nargin < 6
    name = [];
end

if nargin < 7 || isempty(specs)
    specs  = {'-', '--', ':', '-', '-.', '-', '-', '-', '-'};
elseif length(specs) < length(vals)
    specs = repmat(specs, 1, ceil(length(vals)/length(specs)));
end

if ischar(specs) || numel(specs) < numel(vals)
    specs  = repmat({specs}, 1, numel(vals));
end

if nargin < 8 || isempty(markers)
    markers = {'none', 'none', 'none', 'x', 'none', '+', 'o', '*', '^'};
end
if ischar(markers) || numel(markers) < numel(vals)
    markers  = repmat({markers}, 1, numel(vals));
end

colormap summer;

if iscell(vals{1})
    ngroups = numel(vals);
    cvals = vals;
else
    ngroups = 1;
    cvals = {vals};
end
                           
f = figure; hold on;
lh = [];
colors = get(0,'DefaultAxesColorOrder');
for gr = 1:ngroups
    vals = cvals{gr};
    n_ts = numel(vals);
    fh = {};
    % lh = zeros(1, n_ts);

    for i = 1:n_ts
    mean_vals = nanmean(vals{i});
    std_vals = nanstd(vals{i});
    idx = ~isnan(std_vals);
    h = fill([x_vals(idx), fliplr(x_vals(idx))], [mean_vals(idx) - std_vals(idx), ...
          fliplr(mean_vals(idx) + std_vals(idx))], 'o');
    h.FaceAlpha = ALPHA;
    h.EdgeColor = 'none';
    h.FaceColor = colors(gr, :);
    
    mean_vals = nanmean(vals{i});
    idx = ~isnan(mean_vals);
    lh(end + 1) = plot(x_vals(idx), mean_vals(idx), 'linestyle', specs{i}, 'marker', markers{gr},...
                                   'color', colors(gr, :), 'linewidth', 2, 'markersize', 4);

    end

end

axis tight;
xlabel(xtext, 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel(ytext, 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
set(gca, 'FontSize', 15, 'FontName', 'Times');
legend(lh, legend_text, 'location', 'best', 'fontname', 'Times', 'fontsize', 12, 'Interpreter', 'latex');
hold off;



if ~isempty(name)
savefig(['../fig/results/', name, '.fig']);
saveas(f, ['../fig/results/', name, '.png'])
close(f);
end

end