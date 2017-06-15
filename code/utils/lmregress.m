function y = lmregress(w, X)

X = [ones(size(X, 1), 1), X];
y = X*w;

end