function [X, meanX, stdX] = tranf_to_zscore(X, meanX, stdX)

% Standardize each row of matrix X 
% (is X is a scalogram, it is suposed to be Fr x Time oriented)


if nargin < 2
    meanX = mean(X, 2);
end

if nargin < 3
    stdX = std(X, [], 2);
end

if size(meanX, 2) ~= size(X, 2)
   meanX = repmat(meanX, 1, size(X, 2)); 
end


stdX(stdX == 0) = 1;
if size(stdX, 2) ~= size(X, 2)
   stdX = repmat(stdX, 1, size(X, 2)); 
end

X = (X - meanX)./ stdX;

end