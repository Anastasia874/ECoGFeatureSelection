function [resmat, resvec] = calc_opt_value(Q, b, ar)

if ~iscell(Q)
    resmat = ar'*Q*ar - b'*ar;
    resvec = resmat;
    return
end

A = a_to_A(ar);
resmat = A.*b;
resmat = -sum(resmat(:));

A = tensor(A);
for mode = 1:numel(Q)
    tmp = ttm(A, Q{mode}, mode);
    tmp = tmp.*A.data;
	resmat = resmat + sum(tmp(:)); 
end


resvec = 0;
modes = 1:numel(Q);
norms = zeros(1, numel(Q));
for r = 1:size(ar{1}, 1)
    bpart = tensor(b);
    for mode = modes
        norms(mode) = norm(ar{mode}(r, :)).^2;
    end
    for mode = modes
        bpart = ttm(bpart, ar{mode}(r, :), mode);
        resvec = resvec + ar{mode}(r, :)*Q{mode}*ar{mode}(r, :)'*...
                                prod(norms(modes ~= mode));
    end
    resvec = resvec - squeeze(bpart.data);
end

end