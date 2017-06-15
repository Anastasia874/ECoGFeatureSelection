function regfun = regularized_pls(X, y, ncomp, tensor_flag, reg_struct)

% Requires MATLAB Tensor Toolbox Version 2.6 from http://www.sandia.gov/~tgkolda/TensorToolbox/index-2.6.html
% Inputs:
% X [M x N_1 x N_2 x N_3] -- data tensor
% y [M x N] -- target matrix
% Outputs:


if nargin < 5
   reg_struct = {};
   reg_struct.type = 'none'; % 'sobol', 'poly'; 
%    reg_struct.lambda = 1.0;   
%    reg_struct.type = 'poly'; 
%    reg_struct.s = 3;
%    reg_struct.npoly = 5;
%    reg_struct.type = 'sobol'; 
%    reg_struct.s = 3;
end

if nargin < 4
   tensor_flag = 0; 
end


if strcmp(reg_struct.type, 'recursive')
    X = tensor(reshape(X, [], 10, 10, 32));
    regfun = recursive_pls(X, y, ncomp, reg_struct.block_size, ...
                        reg_struct.forgetting_factor);
    return;
end

[X, y] = transform_data_for_regularization(X, y, reg_struct);


if tensor_flag
   X = tensor(X);
   [~, ~, regfun] = npls(X, y, ncomp);
else
    if ~ismatrix(X)
        X = tenmat(X);
        X = X.data;
    end   
    X = reshape(X, size(X, 1), numel(X(1, :)));
    [~,~,~,~, beta_] = plsregress(X, y, ncomp); % beta - coeffs for prediction.
    regfun = @(X) matrix_pls_regress(X, beta_); % Function that makes prediction.
end

% if tensor_flag
%     [~, ~, regfun] = npls(X, y, ncomponents, stnd_flag, add_ones);
% else
%     [~,~,~,~, beta_] = plsregress(x_train, y_train, ncomp); % beta - coeffs for prediction.
%     regfun = @(X)[ones(size(X, 1), 1) X] * beta_;
% end

   
end

function Y = matrix_pls_regress(X, beta_)

X = reshape(X, size(X, 1), numel(X(1, :)));
Y = [ones(size(X, 1), 1) X] * beta_;

end


function [X, y] = transform_data_for_regularization(X, y, reg)

if ~ismatrix(X)
    X = X.data;
end
switch lower(reg.type) 
    case 'poly'
        X_int = smoothing(X, reg.s, reg.npoly);
        X = [X; reg.lambda * (X - X_int)];
        y = [y; zeros(size(y))];
    case 'sobol'
        X_sd = s_derivative(X, reg.s);
        X = [X; reg.lambda * (X - X_sd)];
        y = [y; zeros(size(y))];        
    case 'none'
end


if isfield(reg, 'batch') && ~isempty(reg.batch)
    forgetting_factor = reg.batch{3};
    P = reg.batch{2};
    Q = reg.batch{1};
    if ~ismatrix(P)
        P = P.data;
    end
    if ~ismatrix(Q)
        Q = Q.data;
    end
    X = [forgetting_factor * P; X];
    y = [forgetting_factor * Q; y];
end

end

function X = s_derivative(X, s)

%diff_matr = [0, 1, 0; 1, -4, 1; 0, 1, 0]/4;

diff_matrix = [1, -1]'/2;

for nd = 1:size(X, 3)
for i = 1:s
    X(:, :, nd) = conv2(X(:, :, nd), diff_matrix, 'same');     
end
end

end



function X = smoothing(X, order, sm_size)

xdims = length(size(X));
conv_dims = ones(1, xdims)*sm_size;
conv_matrix = ones(conv_dims);
conv_matrix = conv_matrix / numel(conv_matrix);

for i = 1:order
   X = convn(X, conv_matrix, 'same');    
end


end


function X = spine_interpolation(X, n, npoly)

assert(length(size(X)) <=4, 'A data point must not contain more than 3 dims');

for ch = 1:size(X, 4)
    X(:, :, ch) = yx_spline_interp(X(:, :, ch), n, npoly);
end

end


function X = yx_spline_interp(X, n, npoly)

% X is 2-way matrix
% n is spline degree

[nx, ny] = size(X);
% Approximate along Y axis:
sp = spap2(npoly, n+1, 1:ny, X);
% Get spline coeffs
coefsy = fnbrk(sp,'c'); % returns nx x n_y_knots matrix

sp2 = spap2(npoly, n+1, 1:nx, coefsy.');
coefs = fnbrk(sp2,'c').'; % returns n_x_knots x n_y_knots matrix

X = spcol(sp2.knots, sp2.order, 1:nx)*coefs*spcol(sp.knots, sp.order, 1:ny).';

end