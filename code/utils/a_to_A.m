function A = a_to_A(ak)

R = size(ak{1}, 1);
A = cell(1, R);

for r = 1:R
    A{r} = ak{1}(r, :);
    for i = 2:numel(ak)
        A{r} = ttt( tensor(A{r}), tensor(ak{i}(r, :)) );
        A{r} = squeeze(A{r}.data);
    end
end

ndim = length(size(A{1}));
A = cat(ndim+1, A{:});
A = sum(A, ndim+1);

end