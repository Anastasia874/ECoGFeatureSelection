function test_spline_approximation

% add path for create_raw_X_set:
addpath(fullfile(pwd,'..', '..', '..', 'Group474', ...
                           'Gasanov2017ElectrocorticographicData', 'code'));

nsamples = 50;
x = linspace(-2, 2, nsamples); y = linspace(-2, 2, nsamples);
[XX, YY] = meshgrid(x, y);


Z = mvnpdf([XX(:), YY(:)]);
Z = reshape(Z, nsamples, nsamples);

figure;
imagesc(Z); colorbar;
title('Bivariate Gaussian');

n_knots = 10; %nsamples - order;
idx = round(linspace(1, nsamples, n_knots));

% interpolation nodes:
[X1, Y1] = ndgrid(x(idx), y(idx));
F = griddedInterpolant(X1, Y1, Z(idx, idx), 'spline');
disp(F);

% % Example with small grid:
% [x2,y2] = ndgrid(-1:0.2:1,-1:0.2:1);
% figure;
% imagesc(F(x2, y2)); colorbar;
% title('Coarse grid');

% query nodes:
[Xq, Yq] = ndgrid(x, y);
Zq = F(Xq, Yq);
figure;
imagesc(Zq - Z); colorbar;
title('Interpolation errors');

% Bivariate spline approximation in y->x order
y_x_spline_approximation(x, y, Z);


% scalogram example:
experiment_name = '20090611S1_FTT_A_ZenasChao_csv_ECoG32-Motion12';
file_prefix = strcat('data/', experiment_name, '/');
time_points = 10;
timebins = 50;
freqbins = 50;
raw_X_set = create_raw_X_set(file_prefix, time_points, 1.1, 0.1, timebins, 10, 130, freqbins);

scalos = reshape(raw_X_set, timebins, freqbins, 32);

% one electrode
electrode = 1;
scalo = squeeze(scalos(:,:,electrode));
imagesc(scalo); colorbar;


y_x_spline_approximation(1:timebins, 1:freqbins, scalo, 3, 3, 3);

% % no explicit grid:
% [X, Y] = ndgrid(1:2:20, 1:2:20);
% F = griddedInterpolant(X, Y, scalo(idx, idx), 'spline');
% [X, Y] = ndgrid(1:20, 1:20);
% 
% alpha = abs(min(scalo(:))) * 0.01;
% appr_scalo = F(X, Y);
% figure;
% imagesc(abs(appr_scalo - scalo) ./ max(abs(scalo), alpha) ); colorbar;
% title('Interpolation errors');



end


function [Zq, sp, sp2] = y_x_spline_approximation(x, y, Z, ky, kx, n_pieces)

REG = 0.001;

if nargin < 6
n_pieces = 5;
end
if nargin < 5
ky = 3; %knotsy = augknt(-3:0.25:3, ky);
end
sp = spap2(n_pieces,ky,y,Z);
disp(sp);
coefsy = fnbrk(sp,'coefs'); % get coefs

% 1d-approximation
Zq_y = fnval(sp,y); 
figure;
imagesc(Zq_y); colorbar;
title('1D spline approximation');
figure;
err = log(1 + abs(Zq_y - Z)./ max(abs(Z), REG));
imagesc(err); colorbar;
title('1D spline approximation (log percentage) errors');

if nargin < 4
kx = 3; %knotsx = augknt(-1.5:0.25:1.5,kx); 
end
sp2 = spap2(n_pieces,kx,x, coefsy');
disp(sp2);


coefs = fnbrk(sp2,'coefs').';
Zq = spcol(sp2.knots,kx,x)*coefs*spcol(sp.knots,ky,y).'; 
figure;
imagesc(Zq); colorbar;
title('Bivariate spline approximation');
figure;
err = log(1 + abs(Zq - Z)./ max(abs(Z), REG));
imagesc(err); colorbar;
title('Bivariate spline approximation (log percentage) errors');

end