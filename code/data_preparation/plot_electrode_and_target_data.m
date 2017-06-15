function plot_electrode_and_target_data(data, electrodes, targets, timex, timey, t0, t1)


idx = timex >= t0 & timex <= t1;
timex = timex(idx);
data = data(idx, electrodes);

idx = timey >= t0 & timey <= t1;
timey = timey(idx);
targets = targets(idx, :);

% figure; 
% subplot(1, 2, 1);
% hold on;
% for i = 1:size(data, 2)
%     ts = data(:, i);
%     ts = (ts - min(ts))/(max(ts) - min(ts)) + (i - 1);
%     plot(timex, ts, 'k-', 'linewidth', 1.2);    
% end
% % xlabel('Time, s', 'FontSize', 18, 'FontName', 'Times', ...
% % 'Interpreter','latex');
% set(gca, 'ytick', []);
% ylabel('Electrodes', 'FontSize', 18, 'FontName', 'Times',  'Interpreter','latex');
% set(gca, 'FontSize', 15, 'FontName', 'Times');
% axis tight;
% 
% subplot(1, 2, 2);
% hold on;
% for i = 1:size(targets, 2)
%     ts = targets(:, i);
%     ts = (ts - min(ts))/(max(ts) - min(ts)) + (i - 1);
%     plot(timey, ts, 'b-', 'linewidth', 2);    
% end
% set(gca, 'ytick', 0.5:1:2.5);
% set(gca, 'yticklabel', {'x', 'y', 'z'});
% ylabel('Wrist coordinates', 'FontSize', 18, 'FontName', 'Times',  'Interpreter','latex');
% set(gca, 'FontSize', 15, 'FontName', 'Times');
% axis tight;


figure; 
hold on;
% for i = 1:size(targets, 2)
%     ts = targets(:, i);
%     ts = (ts - min(ts))/(max(ts) - min(ts)) + (i - 1);
%     plot(timey, ts, 'b-', 'linewidth', 2);   
%     plot(timey(1), ts(1), 'r^', 'linewidth', 2, 'markersize', 9);  
%     plot(timey(end), ts(end), 'ro', 'linewidth', 2, 'markersize', 9);  
% end
for i = 1:size(data, 2)
    ts = data(:, i);
    ts = (ts - min(ts))/(max(ts) - min(ts)) +  size(targets, 2) + (i - 1);
    plot(timex, ts, 'k-', 'linewidth', 1.2);    
end

elctrtxt = arrayfun(@(x) ['El. ', num2str(x)], electrodes, 'UniformOutput', 0);
set(gca, 'ytick', 0.5:1:(size(electrodes, 2) + 2.5));
set(gca, 'yticklabel', ['x ', 'y ', 'z ', elctrtxt]);
xlabel('Time, s', 'FontSize', 18, 'FontName', 'Times', 'Interpreter','latex');
set(gca, 'FontSize', 15, 'FontName', 'Times');
axis tight;

figure; hold on;
plot3(targets(:, 1), targets(:, 2), targets(:, 3), 'b-', 'linewidth', 2);
plot3(targets(1, 1), targets(1, 2), targets(1, 3), 'r^', 'linewidth', 2, 'markersize', 10);
plot3(targets(end, 1), targets(end, 2), targets(end, 3), 'ro', 'linewidth', 2, 'markersize', 10);
grid on;
xlabel('$x$', 'FontSize', 18, 'FontName', 'Times',  'Interpreter','latex');
ylabel('$y$', 'FontSize', 18, 'FontName', 'Times',  'Interpreter','latex');
zlabel('$z$', 'FontSize', 18, 'FontName', 'Times',  'Interpreter','latex');
set(gca, 'xtick', linspace(min(targets(:, 1)), max(targets(:, 1)), 10));
set(gca, 'ytick', linspace(min(targets(:, 2)), max(targets(:, 2)), 10));
set(gca, 'ztick', linspace(min(targets(:, 3)), max(targets(:, 3)), 10));
set(gca, 'xticklabel', cell(1, 10));
set(gca, 'yticklabel', cell(1, 10));
set(gca, 'zticklabel', cell(1, 10));
set(gca, 'FontSize', 15, 'FontName', 'Times');
axis tight;



end