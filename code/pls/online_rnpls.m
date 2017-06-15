function [regfun, T, W, beta, mse, Xblock] = online_rnpls(Xblock, T, W, beta, ...
                                                   Xnext, ynext, ...
                                                   forgetting_factor)

% Recursive NPLS for 'online' data processing
% Inputs: 
% Xblock is the previous block of data, [M x I1 x I2 x I3] tensor
% T - [M x ncomps] matrix of projections into new coordinates
% W - {1 x 4} cell of [In x ncomps] weight matrices
% Xnext, ynext (tensor, [M x N] matrix) - next data blocks to process 
% forgetting_factor - scalar in (0, 1]. Determines, how much previous
% results influence current block processing
% Outputs:
% regfun - handle to regression functions with tensor input
% T, W, beta - updated matrices. (beta is [])
% P ([ncomps x I1 x I2 x I3]), Q ([ncomps x N])- loadings to input as parts 
% of the next block

Xnext = tensor(Xnext);

if isempty(Xblock)
    % for the first iteration, Xblock is empty and T specifies ncomponents:
    [W, beta, regfun, mse, T] = npls(Xnext, ynext, T, 0);   
    Xblock = Xnext;
    return;
end

ncomps = size(T, 2);

[orthT, ~] = qr(T); % orthogonalization

% P is [ncomps x I1 x I2 x I3] tensor
P = x_loadings(Xblock, orthT(:, 1:ncomps), T, W);
Q = orthT(:, 1:ncomps)' * T * beta;   


Xblock = tenzeros([ncomps + Xnext.size(1), Xnext.size(2:4)]);
Xblock(1:ncomps, :, :, :) = forgetting_factor * P;
Xblock(ncomps + 1:end, :, :, :) = Xnext;
yblock = [forgetting_factor * Q; ynext];
%Xblock = cat(1, Xblock{:});
[W, beta, regfun, mse, T] = npls(Xblock, yblock, ncomps, 0); 


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

