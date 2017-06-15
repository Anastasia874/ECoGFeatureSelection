function [nfeats, modes] = nfeatures(res)

if isfield(res, 'params') && isfield(res.params, 'modes')
    modes = res.params.modes;
elseif isfield(res, 'ak')
    modes = arrayfun(@(x) length(x{1}), res.ak{1});
elseif isfield(res, 'A')
    modes = size(res.A{1});
end
nfeats = prod(modes);
end