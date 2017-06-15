function xx = reshape_2D_matfeatures(x, nchan, nfreqs)
% This script reshapes x into nchan x (1 + nfreqs) matrix
% x is a [1x nchan(1 + nfreqs)] vec such that :
%   1--nchan entries correspond to time series;
%   nchan + (1--nfreqs)   correspond to scalograms along 1st channel
%   nchan + nfreqs + (1--nfreqs) correspond to scs along 2nd channel

xx = zeros(nchan, 1 + nfreqs);
xx(:, 1) = x(1:nchan);

for ch = 1:nchan
    xx(ch, 2:end) = x(nchan + (ch-1)*nfreqs + 1:nchan + ch*nfreqs);
end

end