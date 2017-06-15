function [A, solved, ak, msg] = solve_tns_opt_problem(Q, b, niters, R, init)

% R is approximately the number of selected features
if nargin < 4
    R = 50;
end
nmodes = length(size(b));
assert(length(Q) == nmodes, 'Number of entries in Q must equal modality of b');

% initialize arrays:
if isempty(init) || isempty(init{1})
    ak = arrayfun( @(i) ones(R, i), size(b), 'UniformOutput', 0);
else
    ak = init;
end

qmat = zeros(1, niters);
qvec = zeros(1, niters);
msg = '';
try
    for k = 1:niters
        for i = 1:nmodes
           [Qk, bk] = block_diag_Q(Q, b, ak, i);
            n = size(Qk, 1);        
            cvx_begin  quiet
                variable x(n, 1) nonnegative;
                minimize (x'*Qk*x - bk'*x)
                subject to
                     norm(x, 1) <= 1;
    %                 0 <= x <= 1;
            cvx_end
            ak{i} = reshape(x, size(ak{i})); %cut_and_reshape(x, size(ak{i}), 5);
        end
        A = a_to_A(ak);
        [qmat(k), qvec(k)] = calc_opt_value(Q, b, ak);
        fprintf('TQPFS: iter % i / %i; norm(A) = %e, qmat = %7.1e, qvec = %7.1e\n', ...
                            k, niters, norm(A(:)), qmat(k), qvec(k));
    end
    A = a_to_A(ak);
    solved = 1;
catch ME
    msg = ME.message;
    disp(msg);
    cvx_clear;
    solved = 0;
    A = ones(size(b));
end
    
    
end


function a = cut_and_reshape(x, sizes, thrs)

if thrs > 1
    quantiles = linspace(0.95, 0.5, thrs);
%     thrs = linspace(max(x), min(x), thrs);
end

for qn = quantiles
    thrs = quantile(x, qn);
    a = reshape(1 *(x > thrs), sizes);
    if all(sum(a, 2) > 0)
        return;
    end
end

if all(sum(a, 2) > 0)
   disp('One or more of a_r is zero');
end

end

function [bdQ, Bk] = block_diag_Q(Q, b, a, i)

assert(iscell(a));
bdQ = cell(1, size(a{1}, 1));
Bk = bdQ;

idx_modes = find(~ismember(1:numel(a), i));
for r = 1:size(a{1}, 1)
    bdQ{r} = Q{i};
    Bk{r} = tensor(b);
    normprod = 1;
    for j = idx_modes
        na = norm(a{j}(r, :))^2;
        bdQ{r} = bdQ{r} * na;
        Bk{r} = ttm(Bk{r}, squeeze(a{j}(r, :)), j);
        normprod = normprod * na;
    end
    for j = idx_modes
        bdQ{r} = bdQ{r} + eye(size(bdQ{r})) * (a{j}(r, :) * Q{j} * a{j}(r, :)') *...
                                            normprod / (norm(a{j}(r, :))^2);
    end
    Bk{r} = squeeze(Bk{r}.data);
    Bk{r} = Bk{r}(:);
end
bdQ = blkdiag(bdQ{:});
Bk = vertcat(Bk{:});

% assert(iscell(Q));
% assert(iscell(a));
% idx = 1:numel(a);
% for i = 1:length(a)
%     Q{i} = prod(na(idx ~= i) * Q{i});
% end
% 
% bdQ = blkdiag(Q{:});
end