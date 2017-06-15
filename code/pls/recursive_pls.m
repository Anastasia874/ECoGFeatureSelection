function regfun = recursive_pls(X, y, ncomponents, block_size, forgetting_factor)


nsamples = size(X, 1);
nblocks = ceil(nsamples / block_size);

% first run:
Xblock = X(1:min(block_size, nsamples), :, :, :);
yblock = y(1:min(block_size, nsamples), :);
mse = cell(1, nblocks);
[W, beta, regfun, mse{1}, T] = npls(Xblock, yblock, ncomponents, 0);
ncomps = size(T, 2);

for nb = 2:nblocks
   [orthT, ~] = qr(T); % orthogonalization
   P = x_loadings(Xblock, orthT(:, 1:ncomps), T, W);
   Q = orthT(:, 1:ncomps)' * T * beta;   
   
   idx1 = block_size * (nb - 1) + 1; 
   idx2 = min(block_size*nb, nsamples);
   X1 = X(idx1:idx2, :, :, :);
   Xblock = tenzeros([ncomps + X1.size(1), X1.size(2:4)]);
   Xblock(1:ncomps, :, :, :) = forgetting_factor * P;
   Xblock(ncomps + 1:end, :, :, :) = X1;
   yblock = [forgetting_factor * Q; y(idx1:idx2, :)];
   %Xblock = cat(1, Xblock{:});
   [W, beta, regfun, mse{nb}, T] = npls(Xblock, yblock, ncomponents, 0); 
end

end

function P = x_loadings(X, orthT, T, W)

ncomps = size(T, 2);
P = tenones(ncomps, X.size(2:4));
for i = 1:ncomps
   P(i, :,:,:) = ttm(x_reconstruction(tensor(T(:, i)), W(:, i)), orthT(:, i), 1, 't');
end


E = X - ttm(P, orthT, 1);
%P = P';
P = P + ttm(E, orthT, 1, 't');

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