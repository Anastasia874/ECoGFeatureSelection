function plot_y_data_points(y, Y_set, motion_markers)

% y contains all the data, Y_set - only the selected points

MARKER_NAMES = {'LSHO', 'LELB', 'RSHO', 'RELB', 'RWRI', 'LUpperArm',...
                'LWristOut', 'LWristIn', 'LThumb', 'LPinky', 'LMidFinger', ...
                'RHND'};
FOLDER = '../fig/';

if nargin < 3
    motion_markers = MARKER_NAMES;
end

for i = 1:length(motion_markers)
f = figure;
hold on;
plot3(y(:, 3*(i-1) + 1), y(:, 3*(i-1) + 2), ...
             y(:, 3*i));
title(motion_markers{i});
    if ~isempty(Y_set)
        plot3(Y_set(:, 3*(i-1) + 1), Y_set(:, 3*(i-1) + 2), Y_set(:, 3*i), '.', ...
          'markersize', 10);
    end
hold off;
xlabel('$x$', 'FontSize', 20, 'FontName', 'Times', ...
    'Interpreter','latex');
ylabel('$y$', 'FontSize', 20, 'FontName', 'Times', ...
    'Interpreter','latex');
zlabel('$z$', 'FontSize', 20, 'FontName', 'Times', ...
    'Interpreter','latex');
h = legend({'Trajectory', 'Selected time points'});
h.Location = 'best';
h.FontName = 'Times';
h.FontSize = 15;
set(gca, 'FontSize', 15, 'FontName', 'Times');
savefig([FOLDER, motion_markers{i}, '.fig']);
saveas(f, [FOLDER, motion_markers{i}, '.png'])
close(f);
end

end

% Plot the targets:
% figure;
% hold on;
% for i = 1:length(motion_markers)
%    plot3(Y_set(:, 3*(i-1) + 1), Y_set(:, 3*(i-1) + 2), Y_set(:, 3*i));
% end
% hold off;
