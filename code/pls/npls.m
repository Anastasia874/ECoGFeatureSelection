function [W, beta, regfun, mse, T] = npls(X, y, ncomponents, stnd_flag)
% Alg. 1 from  Eliseev et al. 2011. Iterative N-way partial least squares 
% for a binary self-paced brain–computer interface in freely moving animals
% Requires MATLAB Tensor Toolbox Version 2.6 from http://www.sandia.gov/~tgkolda/TensorToolbox/index-2.6.html
% Inputs:
% X [M x N_1 x N_2 x N_3] -- data tensor
% y [M x N] -- target matrix
% Outputs:

if nargin < 4
    stnd_flag = 0;
end



% Center both predictors and response, and do PLS
m = size(X, 1);

if stnd_flag 
stdX = collapse(X, 1, @std);
meanX = collapse(X, 1, @mean);
stdY = std(y, 1);
meanY = mean(y, 1);
X = (X - squeeze(ttt(tenones(m, 1), meanX))) ./ squeeze(ttt(tenones(m, 1), stdX));
y = bsxfun(@minus, y, meanY);
y = y./repmat(stdY, size(y, 1), 1);
else
    stdX = tenones(X.size(2:end));
    meanX = tenzeros(X.size(2:end));
    stdY = ones(1, size(y, 2));
    meanY = zeros(1, size(y, 2));
end


% if add_ones
%    X =  
% end

tmp_y = y;
tmp_X = X;
mse = zeros(2, ncomponents + 1);
mse(:, 1) = [norm(X), norm(y)]';
% fprintf('Starting with norm X: %0.2f, y: %0.2f', norm(X), norm(y));
W = cell(ndims(X), ncomponents);
beta = zeros(ncomponents, size(y, 2)); %cell(1, ncomponents);
T = zeros(size(X, 1), ncomponents);


for iter = 1:ncomponents
    [tmp_W, tmp_t] = pls_iteration(tmp_X, tmp_y);     
    W(:, iter) = tmp_W;
    T(:, iter) = tmp_t; % stack the new loading vecor to the end
    tmp_beta = (T(:, 1:iter)'*T(:, 1:iter))\T(:, 1:iter)'*tmp_y;
    beta(1:iter, :) = beta(1:iter, :) + tmp_beta;
    tmp_y = tmp_y - T(:, 1:iter)*tmp_beta;
    tmp_X = tmp_X - x_reconstruction(tensor(tmp_t), tmp_W);
    mse(1, iter + 1) = norm(tmp_X);
    mse(2, iter + 1) = norm(tmp_y);
%     fprintf('N. comps. %d, residual norm X: %0.2f, y: %0.2f;\n', ...
%         iter, norm(tmp_X), norm(tmp_y));
    
end

regfun = @(X) pls_prediction(X, W, beta, meanX, meanY, stdX, stdY);
% plotyy([0, 1:ncomponents], resid_x, [0, 1:ncomponents], resid_y);

end


function y = pls_prediction(X, W, beta, meanX, meanY, stdX, stdY)
% PlS regression function for tensor data.
% W cell-array [ndims(X) x ncomps] - components decomposition (normalized, 
%                                    include m x 1 tensor) 
% beta [ncomps x ny] - regression coefficients

m = size(X, 1);
X = X .* squeeze(ttt(tenones(m, 1), stdX));
X = X - squeeze(ttt(tenones(m, 1), meanX));

ncomps = size(W, 2);
tmp_X = X;
T = zeros(m, ncomps);
for i = 1:ncomps
    t = t_projection(tmp_X, W(:, i));
    tmp_X = tmp_X - x_reconstruction(tensor(t), W(:, i));
    T(:, i) = t;
end

y = (T*beta).*repmat(stdY, m, 1);
y = bsxfun(@plus, y, meanY);

end


function tw = x_reconstruction(t, W)

tw = t;
for i = 2:numel(W)
   tw = squeeze(ttt(tw, tensor(W{i})));
end    
end

function t = t_projection(X, W)

t = X;
for i = numel(W):-1:2
   t = ttm(t, W{i}, i, 't');
end 

% convert to standard MATLAB matrix:
t = tenmat(squeeze(t), 1);
t = t.data;
end


function [W, T] = pls_iteration(X, y)

Z = ttm(X, y, 1, 't');
% find best rank-1 approximation of Z (no print):
cp = cp_als(Z, 1, 'printitn', 0); %  'dimorder', [3 2 1]);

W = cp.U; % already normalized
T = t_projection(X, W);
end


% function pct_var = percent_explained_variance(X0, Y0, Xloadings, Yloadings)
% 
% pct_var = [sum(abs(Xloadings).^2,1) ./ sum(sum(abs(X0).^2,1));
%            sum(abs(Yloadings).^2,1) ./ sum(sum(abs(Y0).^2,1))];
% 
% end