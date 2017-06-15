function Qtt = reshape_tns_to_mat_Q(Qt)

% Turn [N1xN1] and [N2xN2] similarity matrices into a single [N1N2xN1N2]
% matrix as a Kronecker product

n1 = size(Qt{1}, 1);
n2 = size(Qt{2}, 1);

Qtt = zeros(n1*n2, n1*n2);
for i = 1:n1
    for j = 1:n1
        Qtt((i-1)*n2 + 1:i*n2, (j-1)*n2 + 1:j*n2) = min(Qt{1}(i, j), Qt{2});  
    end
end



end