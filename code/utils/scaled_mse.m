function smse = scaled_mse(y_pred, y)

smse = sum(eq_dist(y_pred, y)) / sum(eq_dist(y, ...
                                       repmat( mean(y,1), size(y, 1), 1)...
                                ));

end

function eqd = eq_dist(x, y)

eqd = sqrt(sum((x - y).*(x - y), 2));
end
