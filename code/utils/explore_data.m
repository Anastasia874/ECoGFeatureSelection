function params = explore_data

% Based on Makarchuk2016ECoGSignals/code
addpath(fullfile(pwd,'..', '..', '..', 'Group374', 'Makarchuk2016ECoGSignals', 'code'));
addpath(fullfile(pwd, '..', '..', '..', '..', 'MATLAB', 'tensor_toolbox_2.6'));
addpath(fullfile(pwd, 'utils'));

experiments = {'20090116S1_FTT_A_ZenasChao_csv_ECoG32-Motion10', ...
               '20090527S1_FTT_K1_ZenasChao_csv_ECoG64-Motion8', ...
               '20090602S1_FTT_K1_ZenasChao_csv_ECoG64-Motion7', ...
               '20081127S1_FTT_A_ZenasChao_csv_ECoG32-Motion8',...
               '20081224S1_FTT_A_ZenasChao_csv_ECoG32-Motion10', ...
               '20090121S1_FTT_A_ZenasChao_csv_ECoG32-Motion10', ...
               '20090611S1_FTT_A_ZenasChao_csv_ECoG32-Motion12',...
               '20090525S1_FTT_K1_ZenasChao_csv_ECoG64-Motion8', ...
               }; 
           
% params = [];
% params.names = experiments;
% params.maxcorr_time = cell(3, numel(experiments)); % best time delay for each electrode
% params.maxcorr_fr = cell(3, numel(experiments));
% params.maxcorr_logfr = cell(3, numel(experiments));
load('initial_exploration_params.mat');
frscale = 15;
CORRLIM = 0.35;

for nexp = 3:numel(experiments)
experiment_name = experiments{nexp};
file_prefix = strcat('../data/', experiment_name, '/');

D = importdata(strcat(file_prefix, 'Motion.csv'));
motion_time = D.data(:, 1);
motion_data = D.data(:, 2:end);
markers = D.colheaders(2:end);
MARKER = 'RWR';
mk_idx = cellfun(@(x) ~isempty(strfind(lower(x), lower(MARKER))), markers, 'UniformOutput', 1);
exp_idx = cellfun(@(x) isempty(strfind(lower(x), 'exp')), markers, 'UniformOutput', 1);

D = importdata(strcat(file_prefix, 'ECoG.csv'));
time = D.data(:, 1);
data = D.data(:, 2:end);
electrodes = D.colheaders(2:end);
nchan = length(electrodes);

idx = strfind(experiment_name, '_A_');
if isempty(idx);  idx = strfind(experiment_name, '_K1_') + 3; 
else idx = idx + 2; end
experiment_name = experiment_name(1:idx);

% % Look for correlations between channels in time domain:
% % plot electrode-by-electrode correlations in their spatial locations
% for time_delay = 0:50:500
%     plot_electrode_correlation(data, time_delay, ...
%         ['../fig/initial_exploration/ch_correlations/', experiment_name]);
% end


% time points of interest:
time_points = 0:0.01:950;

% Count actual intersections btw time sticks and time_points:
fprintf('Motion time contains %d time_points \n', sum(ismember(time_points, motion_time)));
fprintf('ECoG time contains %d time_points \n', sum(ismember(time_points, time)));

% To associate time ticks and time_points, use interpolation
motion_data = motion_data(:, mk_idx & exp_idx);

% % 3D plot of the motion data:
% plot_y_data_points(motion_data, [], {MARKER}); 

% % Try interpolation using downsampled data (to save time):
% try_interpolation(motion_data, motion_time, data, time);

% 'upsample' x: increase frequency by factor of 5
time_points_hfr = linspace(time_points(1), time_points(end), ...
                                            length(time_points)*frscale);
idx_lfr = 1:frscale:length(time_points_hfr);

% since interpoation is fast, no downsampling
disp('Interpolatiing motion data');
tic
[y, Fy] = oneD_gridded_interpolation(motion_data, motion_time, ...
                                                time_points, 1);
toc

disp('Interpolatiing ECoG data');
tic
[xhfr, ~] = oneD_gridded_interpolation(data, time, time_points_hfr, 1); 
x = xhfr(idx_lfr, :);
% [x, ~] = oneD_gridded_interpolation([], Fx, time_points, 1);                                          
toc


% Look for correlations between channels and motion data in time domain:
dims = {'x', 'y', 'z'};
delays = -2:0.05:2;
mdl = floor(length(delays)/2);
for j  = [1, 2, 3]
    motion_x = y(:, j);
    corrs = zeros(size(x, 2), length(delays));
    for i = 1:length(delays) 
    %     idx_delayed = time_points >= 2 + t;
    %     idx = time_points < time_points(end) - (2 + t);
         corrs(:, i) = abs(corr(x(i:end - 2*mdl - 1 + i, :), ...
                                              motion_x(mdl + 1:end-mdl)));
    end
    [~, idx] = max(corrs, [], 2);
    params.maxcorr_time{j, nexp} = delays(idx);
    plot_matrix(corrs, delays, 1:nchan, 'Time delays', 'Electrodes', ...
                         dims{j}, [experiment_name, MARKER, '_',dims{j}], ...
                        '../fig/initial_exploration/corrs_by_time/', [0, CORRLIM]);
end


% Look for correlations between channels and motion data in frequency domain:
% d (1.5,4 Hz), h (4,8 Hz), a (8,14 Hz), b1 (14,20 Hz), b2
% (20,30 Hz), c1 (30,50 Hz), c2 (50,90 Hz), c3 (90,120 Hz),
% and c4 (120,150 Hz)
fs = round(1/mean(diff(time_points_hfr)));  
% frequency_bands = [1.5, 3.5, 1; 4, 8, 0.5; 9, 14, 1; ...
%                     15, 20, 1; 21, 30, 1; 31, 49, 1; ...
%                     50, 90, 2; 90, 150, 10; ];
frequency_bands = [1, 14, 1; ...
                    15, 50, 5; ...
                    60, 200, 10];
                
frequency_bands = frequency_bands(frequency_bands(:, 2) < 0.5 * fs, :);                
[fr_range, nbands, fnj] = frequency_range(frequency_bands);
% run scalogram feature extraction w\o removing edge points:


delays = -2:0.5:2;
mdl = floor(length(delays)/2);
dims = {'x', 'y', 'z'};
corrs = zeros(length(electrodes), length(fr_range), length(dims), length(delays));
logcorrs = corrs;    
for i = 1:length(delays)
    for el = 1:length(electrodes)        
        [features, ~, ~] = scalo_by_electrode(xhfr(:, el), 0, ...
                                                  frequency_bands, ...
                                                  fs, 'none');
        features = features(idx_lfr, :);
        logfeatures = log(features);
        logfeatures = tranf_to_zscore(logfeatures')';
        features = tranf_to_zscore(features')';
        for j = 1:length(dims)
            logcorrs(el, :, j, i) = abs(corr(logfeatures(i:end - 2*mdl - 1 + i, :), ...
                y(mdl + 1:end-mdl, j)));
            corrs(el, :, j, i) = abs(corr(features(i:end - 2*mdl - 1 + i, :), ...
                y(mdl + 1:end-mdl, j)));
        end
    end             
%     x, y, xtxt, ytxt, title_txt, figname, folder, clb_limits
    for j = 1:length(dims)
    plot_matrix(logcorrs(:, :, j, i), fr_range, 1:nchan, 'Frequencies', 'Electrodes', ...
                    [MARKER, ' ', dims{j}, '', num2str(delays(i))], ...
                    [experiment_name, MARKER, '_', dims{j}, '_', num2str(delays(i))], ...
                    '../fig/initial_exploration/corrs_by_logfreq/', [0, CORRLIM]);
    plot_matrix(corrs(:, :, j, i), fr_range, 1:nchan, 'Frequencies', 'Electrodes', ...
                    [MARKER, ' ', dims{j}, '', num2str(delays(i))], ...
                    [experiment_name, MARKER, '_', dims{j}, '_', num2str(delays(i))], ...
                    '../fig/initial_exploration/corrs_by_freq/', [0, CORRLIM]);
    end
end
% save best combinations:
for j = 1:length(dims)
    [~, idx] = max(reshape(corrs(:, :, j, :), nchan, []), [], 2);
    [ii, jj] = ind2sub([length(fr_range), length(delays)], idx);
    params.maxcorr_fr{j, nexp} = [fr_range(ii), delays(jj)];
end
save('initial_exploration_params.mat', 'params');
% for i = 1:length(delays)
% corrs = zeros(length(electrodes), length(fr_range), length(dims));
%     
%     for el = 1:length(electrodes)        
%         [features, ~, ~] = scalo_by_electrode(xhfr(:, el), 0, ...
%                                                   frequency_bands, ...
%                                                   fs, 'none');
%         features = tranf_to_zscore(features')';
%         for j = 1:length(dims)
%             corrs(el, :, j) = abs(corr(features(i:end - 2*mdl - 1 + i, :), ...
%                 y(mdl + 1:end-mdl, j)));
%         end
%     end       
%       
%     
%     for j = 1:length(dims)
%     plot_matrix(corrs(:, :, j), fr_range, 1:nchan, 'Frequencies', 'Electrodes', ...
%                     [MARKER, ' ', dims{j}, '', num2str(delays(i))], ...
%                     [experiment_name, MARKER, '_', dims{j}, '_', num2str(delays(i))], ...
%                     '../fig/initial_exploration/corrs_by_freq/');
%     end
% end    
end


end


function try_interpolation(motion_data, motion_time, data, time)

figure; hold on;
ds_rates = [20, 10, 5];
for ds_rate = ds_rates
[interp_mdata, ~] = oneD_gridded_interpolation(motion_data, motion_time, ...
                                                motion_time, ds_rate);
% plot interpolation errors:
mape = safe_mape(motion_data, interp_mdata);
errorbar(mean(mape), std(mape));
end
hold off;
xlabel('Motion markers', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel('Interpolation error (MAPE)', 'FontSize', 20, 'FontName', 'Times', ...
        'Interpreter','latex');
legend(arrayfun(@(x) num2str(x), ds_rates, 'UniformOutput', 0));
set(gca, 'FontSize', 15, 'FontName', 'Times');
axis tight;

% Same for ECoG data:
figure; hold on;
ds_rates = [20, 10, 5, 1];
for ds_rate = ds_rates
[interp_data, ~] = oneD_gridded_interpolation(data, time, time, ds_rate);
% plot interpolation errors:
mape = safe_mape(data, interp_data);
errorbar(mean(mape), std(mape));
end
hold off;
xlabel('Electrodes', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel('Interpolation error (MAPE)', 'FontSize', 20, 'FontName', 'Times', ...
        'Interpreter','latex');
legend(arrayfun(@(x) num2str(x), ds_rates, 'UniformOutput', 0));
set(gca, 'FontSize', 15, 'FontName', 'Times');
axis tight;


end


function error = safe_mape(x, hatx)

denom = abs(x);
denom(x == 0) = mean(abs(x(:)));
error = abs(x - hatx)./denom;

end


% time_step = 1; 
% time_interval = 3;
% 
% time_iters = time_points(1):time_step:time_points(end) - time_interval;
% i = 1; corrs = zeros(size(x, 2), size(y, 2), length(time_iters));
% smcorrs = corrs;
% for t = time_iters  
%     idx = time_points >= t & time_points < t + time_interval;
%     xt = x(idx, :); yt = y(idx, :);
%     xt = xt - repmat(mean(xt), sum(idx), 1);
%     yt = yt - repmat(mean(yt), sum(idx), 1);
%     corrs(:, :, i) = corr(xt, yt);
%     i = i + 1;
% end
% 
% for i = 1:size(corrs, 1)
% for j = 1:size(corrs, 2)
%     smcorrs(i, j, :) = smooth(squeeze(corrs(i, j, :)), 51);    
% end
% end
% 
% smc = reshape(smcorrs, 96, []);
% avcorrs = reshape(mean(smc, 2), 32, 3);
% maxcorrs = reshape(max(smc, [], 2), 32, 3);