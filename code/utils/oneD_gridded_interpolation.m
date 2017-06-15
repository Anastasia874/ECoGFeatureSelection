function [interp_mdata, F] = oneD_gridded_interpolation(data, time, interp_time, ds_rate)
% Computes interpolation model for each dimension of data sampled at time.
% If data is empy, time is expected to contain cell array of precomputed
% models

if isempty(data)
    assert(iscell(time), 'Second argument to oneD_gridded_interpolation should be a cell array');
    [interp_mdata, F] = F_interpolate(time, interp_time);
    return;
end

interp_idx = 1:ds_rate:length(time);
nmarkers = size(data, 2);
F = cell(1, nmarkers);
interp_mdata = zeros(length(interp_time), nmarkers);

for mk = 1:nmarkers
    F{mk} = griddedInterpolant(time(interp_idx), data(interp_idx, mk),...
                                                        'spline');
    interp_mdata(:, mk) = F{mk}(interp_time);
end

end


function [interp_mdata, F] = F_interpolate(F, interp_time)

nmarkers = numel(F);
interp_mdata = zeros(length(interp_time), nmarkers);
for mk = 1:nmarkers
    interp_mdata(:, mk) = F{mk}(interp_time);
end

end