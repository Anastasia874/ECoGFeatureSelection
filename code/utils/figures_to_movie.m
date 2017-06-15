function figures_to_movie

folder = '../fig/qpfs/elec_by_freq_sign_bc/';
dims = {'x', 'y', 'z'};

for d = 1:3
pattern = ['2D_correlelectrode_by_freq_selection_rate_*_sign_bc_alpha0p05_', dims{d}];
figures = dir(fullfile(folder, [pattern, '.fig']));
nfig = length(figures);
sort_by = zeros(1, nfig);
for i = 1:nfig
    name = strsplit(figures(i).name, 'rate_'); name = name{end};
    name = strsplit(name, '_sign'); name = name{1};
    sort_by(i) = str2double(name);
end
[sort_by, idx] = sort(sort_by, 'ascend');


v = VideoWriter(['2D_correl_td0p6_sign_bc_LWR_', dims{d},'.avi']);
v.FrameRate = 3;
open(v);

F(nfig) = struct('cdata',[],'colormap',[]);
for i = 1:nfig
    fig = open([folder, figures(idx(i)).name]);
    title(['complexity = ', num2str(sort_by(i))]);
    colorbar;
    F(i) = getframe(fig);
    close(fig);
    writeVideo(v, F(i));
end
close(v);
% fig = figure;
% axis off;
% movie(fig, F, 1, 3);

end

end