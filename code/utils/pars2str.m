function res = pars2str(pars)

res = '';
fnames = fieldnames(pars);
for i = 1:numel(fnames)
    val = pars.(fnames{i});
    if ~ischar(val)
        val = num2str(val);
    end
    res = [res, fnames{i}, ': ', val, '; '];
end
    
end