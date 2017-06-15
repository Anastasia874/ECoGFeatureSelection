classdef tspartition < cvpartition
   
    methods
        function cv = tspartition(n_samples, n_folds)
            cv = cv@cvpartition(n_samples,'kfold', n_folds);   
            cv.indices = sort(cv.indices);
        end
    end
end


% case 'kfold_ts'
%     if stdargin == 2 || isempty(T)
%         T = dftK;
%     elseif ~isscalar(T) || ~isnumeric(T) || T <= 1 || ...
%             T ~= round(T) || ~isfinite(T)
%         error(message('stats:cvpartition:BadK'));
%     end
% 
%     if  isempty(cv.Group) && T > cv.N
%         warning(message('stats:cvpartition:KfoldGTN'));
%         T = cv.N;
%     elseif ~isempty(cv.Group) && T > length(cv.Group)
%         warning(message('stats:cvpartition:KfoldGTGN'));
%         T = length(cv.Group);
%     end
% 
%     cv.NumTestSets = T; %set the number of fold
%     cv = cv.rerandom(s);