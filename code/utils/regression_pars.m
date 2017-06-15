function [w, pvals] = regression_pars(X_train, y_train)

w = zeros(size(X_train, 2) + 1, size(y_train, 2));
pvals = w;
for j = 1:size(y_train, 2)
    lm = fitlm(X_train, y_train(:, j));
    w(:, j) = lm.Coefficients.Estimate; % the first one is the intercept  
    pvals(:, j) = lm.Coefficients.pValue;  
end

end