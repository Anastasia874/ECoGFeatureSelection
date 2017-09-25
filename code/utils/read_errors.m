function [mse, crr, dtwd, mse_train, crr_train, dtwd_train, crr_ho, ...
                                     made, made_train] = read_errors(err)

MAX_HO = 2;

try
    err = cell2mat(err);
catch ME
    fprintf('%s \n', ME.message);
    if strcmp(ME.identifier, 'MATLAB:cell2mat:InconsistentFieldNames')
        err = padd_error_struct(err, MAX_HO);
    end
    err = cell2mat(err);
end


mse = reshape([err().mse], size(err));    
crr = reshape([err().crr], size(err)); 
dtwd = reshape([err().dtwd], size(err)); 
mse_train = reshape([err().mse_train], size(err)); 
made = reshape([err().made], size(err));   
made_train = reshape([err().made_train], size(err)); 
crr_train = reshape([err().crr_train], size(err)); 
dtwd_train = reshape([err().dtwd_train], size(err)); 
% crr_ho = reshape({err().crr_ho}, size(err)); 
crr_ho_res = cell2mat([err().crr_ho]);
n_vars = size(err(1).crr_ho, 2);
crr_ho = cell(1, n_vars);
for n = 1:n_vars
    crr_ho{n} = reshape(crr_ho_res(n:n_vars:end), size(err));
end

end