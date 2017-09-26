function plot_cv_results_area2_nan(vals, x_vals, ytext, xtext, ...
                                         legend_text, name, specs, markers, iflog)

% Main plotting script for comparing groups time series
% Inputs:
% vals - {1 x ngroups} cell array of {1 x nts} cell arrays. Each entry in
%        {1 x nts} cell array is a [ncvs x nx] matrix. The script plots its
%        mean (by cvs) as a solid line and variance as a shadowed area.
%        NaNs are ok
% xvals - {1 x ngroups} cell array with [1 x nx] x values. If not cell, the
%        same range is used for all groups 
% ytext, xtext - y and x labels
% legend_text - {1 x 2} cell with {1 x nts} and {1 x ngroups} arrays of
%               strings. The first is for labeling ts in the group, the
%               second is for labeling across groups
% name - name for saving. If left empty, the figure won't be saved and will 
%        be left open
% specs - cell array with line style specifiers. If empty, default sequence 
%         will be used (new spec for each ts). If number of specs is less 
%         than nts, the sequence will be repeated 
% markers - same story
% iflog - bolean flag for logarithmic scale in Y

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
    if ~iscell(specs)
        specs = {specs};
    end
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

if nargin < 9
    iflog = 0;
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
lh0 = []; lh1 = []; lh = [];
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

    if i == 1
        lh1(end + 1) = lh(end);
    end
    end
    if gr == 1
        lh0 = lh;
    end
end
if iflog; f.Children(1).YScale = 'log'; end;
axis tight;
xlabel(xtext, 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel(ytext, 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
set(gca, 'FontSize', 15, 'FontName', 'Times');
if ~iscell(legend_text{1})
legend(lh, legend_text, 'location', 'best', 'fontname', 'Times', 'fontsize', 12, 'Interpreter', 'latex');
else
legend_text{1}{end} = [legend_text{1}{end}, ', ', legend_text{2}{1}];
legend(lh0, legend_text{1}, 'location', 'north', ...
        'orientation', 'horizontal','fontname', 'Times', 'fontsize', 15);
ah=axes('position',get(gca,'position'), 'visible','off');
legend(ah, lh1(2:end), legend_text{2}(2:end), 'location', 'best', ...
        'fontname', 'Times', 'fontsize', 15);
    
end
hold off;


if ~isempty(name)
folder_from_name = fileparts(name);
folder = fullfile('../fig/batch_qpfs/', folder_from_name);
if ~isdir(folder)
    mkdir(folder);
end
savefig(['../fig/results/', name, '.fig']);
saveas(f, ['../fig/results/', name, '.png'])
close(f);
end

end