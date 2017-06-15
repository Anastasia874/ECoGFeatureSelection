function [Y_set, marker_names] = create_Y_set(file_prefix, time_points, file_out, ds_rate)

if nargin < 4
    ds_rate = 6;
end

if nargin < 3
    file_out = nan;
end

text_for_console = sprintf('Importing Motion. Downsampling at rate = %d', ds_rate);
disp(text_for_console);


try
% try reading csv first
d_Mot = importdata(strcat(file_prefix, 'Motion.csv')); 

d_Mot.time = d_Mot.data(:, 1);
d_Mot.data = d_Mot.data(:, 2:end);


catch
    res = importdata(strcat(file_prefix, 'Motion.mat'));
    d_Mot.time = res.MotionTime';
    d_Mot.data = cell2mat(res.MotionData');
end

d_Mot.time = downsample(d_Mot.time, ds_rate);
d_Mot.data = downsample(d_Mot.data, ds_rate);

disp('Normalizing motor parameters.');
d_Mot.data = zscore(d_Mot.data);
marker_names = d_Mot.colheaders;

disp('Creating Y_set with motion markers.');
Y_set = Y_sample_extraction(time_points, d_Mot.data, d_Mot.time);

if ~isnan(file_out)
    save(file_out, 'Y_set', 'marker_names');
end


end
