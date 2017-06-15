function fill_electrodes_template(colors, txt, figname)

% Color electrode templates in accordance with variable 'colors'
% Numbers of electrodes are shown in data/A.png and data/B.png

nchannels = length(colors);
if nchannels == 64
   load('saved data/64_channels_template.mat');   
   filledsz = 145;
   elsize = 16;
   dx = -14;
elseif nchannels == 32
   load('saved data/32_channels_template.mat');   
   filledsz = 400;
   elsize = 25;    
   dx = -elsize/2;
else
    fprintf('No templates for %i channels, only for 32 and 64 \n', nchannels);
    return;
end

if nargin < 2
    txt = '';
end

if nargin < 3
    figname = [];
end

if size(colors, 1) == 2 
    labels = colors(2, :);
    colors = colors(1, :);
elseif size(colors, 2) == 2
    labels = colors(:, 2);
    colors = colors(:, 1);      
else
    labels = [];
end
labels = arrayfun(@(x) num2str(x), labels, 'UniformOutput', 0);  


f = figure; imshow(im); hold on;
scatter(pos(1, :), pos(2, :), filledsz, colors, 'filled');
plot(pos(1, :), pos(2, :), 'ko', 'markersize', elsize);
if ~isempty(labels)
    text(pos(1, :)+dx, pos(2, :), labels, 'FontSize', 12, 'Color', 'r');
end
title(txt);
cbh = colorbar;
cblabels = linspace(min(colors), max(colors), length(cbh.Ticks));
cbh.TickLabels = arrayfun(@(x) num2str(x, '%0.2f'), cblabels, 'UniformOutput', 0);
cbh.FontSize = 12;
cbh.FontName = 'Times';

if ~isempty(figname)
    savefig([figname, '.fig']);
    saveas(f, [figname, '.png'])
    close(f);
end

end