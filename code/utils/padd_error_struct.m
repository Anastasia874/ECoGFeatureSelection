function err = padd_error_struct(err, nho, check_fieldnames)

if nargin < 2
    nho = 2;
end

x_holdout = cell(1, nho);

if nargin < 3
check_fieldnames = {'mse', 'crr', 'dtwd', 'mse_train', 'crr_train', 'dtwd_train', ...
                                            'made', 'made_train', 'crr_ho'};
end
if ~iscell(check_fieldnames)
    check_fieldnames = {check_fieldnames};
end

for j = 1:size(err, 2)
    for i = 1:size(err, 1)
        if isempty(err{i, j})
            err{i, j} = nan_errors(x_holdout);
        else
            for fn = 1:numel(check_fieldnames)
                if ~isfield(err{i,j}, check_fieldnames{fn})
                    err{i, j}.(check_fieldnames{fn}) = nan;
                end
            end
            if ismember('crr_ho', check_fieldnames) && ...
                    ~isfield(err{i,j}, 'crr_ho') && numel(err{i,j}.crr_ho) < nho
                n = numel(err{i, j}.crr_ho);
                err{i, j}.crr_ho(end+1:end+rho-n) = cell(1, rho-n);
            end
        end
    end
end


end