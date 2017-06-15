function plot_xyz_coordinates(time_points, y, y_predicted, num_obs, model_name, sm, fname)

titletxt = strrep(model_name, '_', ', ');
y_pred_sm = zeros(size(y_predicted));

f = figure;
dims = {'x', 'y', 'z'};
for d = 1:length(dims)
y_pred_sm(:, d) = smooth(y_predicted(:, d), sm);

subplot(3, 1, d);
hold on;    
h(1) = plot(time_points, y(:, d), 'b-', 'linewidth', 1);
h(2) = plot(time_points, y_pred_sm(:, d), 'r-', 'linewidth', 1);
hold off;
% xlabel('Time, s', 'FontSize', 18, 'FontName', 'Times', ...
% 'Interpreter','latex');
ylabel(dims{d}, 'FontSize', 18, 'FontName', 'Times', ...
    'Interpreter','latex');
set(gca, 'FontSize', 15, 'FontName', 'Times');
axis tight;

% subplot(3, 1, 2);
% hold on;    
% plot(time_points, y(:, 2), 'b-', 'linewidth', 1);
% plot(time_points, y_predicted(:, 2), 'r-', 'linewidth', 1);
% hold off;
% % xlabel('Time, s', 'FontSize', 18, 'FontName', 'Times', ...
% % 'Interpreter','latex');
% ylabel('Y', 'FontSize', 18, 'FontName', 'Times', ...
%     'Interpreter','latex');
% set(gca, 'FontSize', 15, 'FontName', 'Times');
% axis tight;
% 
% subplot(3, 1, 3);
% hold on;    
% plot(time_points, y(:, 3), 'b-', 'linewidth', 1);
% plot(time_points, y_predicted(:, 3), 'r-', 'linewidth', 1);
% hold off;
% xlabel('Time, s', 'FontSize', 18, 'FontName', 'Times', ...
% 'Interpreter','latex');
% ylabel('Z', 'FontSize', 18, 'FontName', 'Times', ...
%     'Interpreter','latex');
% set(gca, 'FontSize', 15, 'FontName', 'Times');
% axis tight;
end
% add common title:
lh = legend(h, {'True', 'Predicted'}, 'location', 'best', 'fontname', 'Times', 'fontsize', 10);
axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0  1], ...
    'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');

text(0.5, 1, ['\bf ', titletxt], 'HorizontalAlignment', 'center', ...
                                    'VerticalAlignment', 'top');
                             
                                
% move legend
new_position = [0.7 0.94 0.07 0.07];
new_units = 'normalized';
set(lh,'Position', new_position,'Units', new_units, 'Orientation', 'horizontal');

save_name = [model_name, fname];
savefig(['../fig/frc_results/', save_name, '.fig']);
saveas(f, ['../fig/frc_results/', save_name, '.png'])
close(f);

for d = 1:length(dims)
f = figure('Name', ['20090121S1, ', dims{d}], 'NumberTitle','off');
xlabel('Time', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel(['LWR position (', dims{d},')'], 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');


hold on;
plot(time_points', y(:, d), '-');
plot(time_points(1:num_obs)', y_pred_sm(1:num_obs, d), 'k-');
plot(time_points(1 + num_obs:end)', y_pred_sm(1 + num_obs:end, d), 'r-');
h = legend('True', 'Train prediction', 'Test prediction');
h.Location = 'best';
mape_train = mean(abs((y(1:num_obs, d) - y_pred_sm(1:num_obs, d))./y(1:num_obs, d)));   
mape_test = mean(abs((y(num_obs + 1:end, d) - y_pred_sm(num_obs + 1:end, d))./...
                                                    y(num_obs + 1:end, d)));
crr_train = corr(y(1:num_obs, d), y_pred_sm(1:num_obs, d));
crr_test = corr(y(1 + num_obs:end, d), y_pred_sm(1 + num_obs:end, d));
% plot([time_points(num_obs), time_points(num_obs)], [min(y(:, d)), max(y(:, d))], 'k:');
title([titletxt, '; corr = ', num2str(crr_train), '/', num2str(crr_test), ...
    ', mape = ', num2str(mape_train), '/', num2str(mape_test)])
axis tight;
% title(titletxt);
set(gca, 'FontSize', 15, 'FontName', 'Times');
savefig(['../fig/frc_results/', save_name, '_', dims{d}, '.fig']);
saveas(f, ['../fig/frc_results/', save_name, '_', dims{d}, '.png']);
close(f);
end

end