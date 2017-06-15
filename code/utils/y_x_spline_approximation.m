function [Zq, sp, sp2] = y_x_spline_approximation(x, y, Z, ky, kx, n_ypieces, ...
                                                                   n_xpieces)

% Bispline approximation as tensor product of spline approximation in first
% in y direction, than in x direction
% x [1 x nx] vector to form xknots from (if empty, this will be [1 : nx])
% y [1 x ny] vector to form yknots from (if empty, this will be [1 : ny])
% Z [ny x nx] matrix
% kx - x order
% ky - y order
% n_pieces

REG = 0.001;

if isempty(x)
    x = 1:size(Z, 1);
end

if isempty(y)
    y = 1:size(Z, 2);
end

if nargin < 6
    n_xpieces = 5;
    n_ypieces = 5;
end

if nargin < 5
ky = 3; %knotsy = augknt(-3:0.25:3, ky);
end
sp = spap2(n_ypieces, ky, y, Z);
disp(sp);
coefsy = fnbrk(sp, 'coefs'); % get coefs

% % 1d-approximation
% Zq_y = fnval(sp,y); 
% figure;
% imagesc(Zq_y); colorbar;
% title('1D spline approximation');
% figure;
% err = log(1 + abs(Zq_y - Z)./ max(abs(Z), REG));
% imagesc(err); colorbar;
% title('1D spline approximation (log percentage) errors');

if nargin < 4
kx = 3; %knotsx = augknt(-1.5:0.25:1.5,kx); 
end
sp2 = spap2(n_xpieces, kx, x, coefsy');
disp(sp2);


coefs = fnbrk(sp2, 'coefs').';
Zq = spcol(sp2.knots, kx, x)*coefs*spcol(sp.knots, ky, y).'; 
% figure;
% imagesc(Zq); colorbar;
% title('Bivariate spline approximation');
% figure;
% err = log(1 + abs(Zq - Z)./ max(abs(Z), REG));
% imagesc(err); colorbar;
% title('Bivariate spline approximation (log percentage) errors');

end