function cerror = correlation_error(y_predicted, y_test, max_delta)

% y_predicted = y_predicted(:);
% y_test = y_test(:);

if nargin < 3
    max_delta = 1; % for no reason
end

corr_col = @(col)corr(y_test(:, col), y_predicted(:,col));
cerror = arrayfun(corr_col, 1:size(y_test,2)); 
cerror = mean(cerror);

% corr_list = zeros(1, max_delta);
% for i = 1:max_delta
%     tmp  = corrcoef(y_test(i:end, :), y_predicted(1:end - i + 1, :));
%     corr_list(i) = corr_func(y_test(i:end, :), y_predicted(1:end - i + 1, :));%tmp(1, 2);
% end
% 
% [cerror, idx] = max(corr_list);
% fprintf('Opt. pos. = %d, correlation = %d \n', idx, cerror);

end

function pears_cor = corr_func(y1, y2)

cy1 = y1 - repmat(mean(y1, 1), size(y1, 1), 1);
cy2 = y2 - repmat(mean(y2, 1), size(y2, 1), 1);
pears_cor = sum(cy1.*cy2, 1) ./ sqrt(sum(cy1.*cy1, 1).*(sum(cy2.*cy2, 1)));
pears_cor = mean(pears_cor, 2);

end