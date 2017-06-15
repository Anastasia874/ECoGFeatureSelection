function matrX = fs_tensor_to_matrix(A, X)

idx = A(:) > 0;

matrX = reshape(X, [], numel(A));
matrX = matrX(:, idx); 
    
end