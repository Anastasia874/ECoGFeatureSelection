function Y = Y_sample_extraction( time_points, motion_data, motion_time )
% Returns set of responces. time_points should by string vector.
% time_points [1 x n_points] - starting time points for dataset creation
% motion_data [T x n_dims] - contains matrix of Y observations for selected
% markers
% motion_data [1 x T] - contains time stamps for the motion data

assert(size(time_points, 1) == 1);

time_points = time_points';
Y = zeros(length(time_points), size(motion_data, 2));

for nt = 1:length(time_points)
    Y(nt, :) =  motion_data(find(motion_time >= time_points(nt), 1), :);
end

end

% function motion = motion_extraction( motion_data, motion_time, time_point )
% %Returns the first record of motion parameters after specified time time_point.
% motion = motion_data(find(motion_time >= time_point, 1), :);
% 
% end
