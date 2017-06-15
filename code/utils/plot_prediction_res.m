function plot_prediction_res(y_predicted, y, name, folder)

FOLDER = 'fig/';
if nargin < 3
    name = [];
end
if nargin < 4
    folder = FOLDER;
end

f = figure;
hold on;
plot3(y(:, 1), y(:, 2), y(:, 3));
plot3(y_predicted(:, 1), y_predicted(:, 2), y_predicted(:, 3), '-');
hold off;
xlabel('$x$', 'FontSize', 20, 'FontName', 'Times', ...
    'Interpreter','latex');
ylabel('$y$', 'FontSize', 20, 'FontName', 'Times', ...
    'Interpreter','latex');
zlabel('$z$', 'FontSize', 20, 'FontName', 'Times', ...
    'Interpreter','latex');
h = legend({'True', 'Predicted'});
h.Location = 'best';
h.FontName = 'Times';
h.FontSize = 15;
set(gca, 'FontSize', 15, 'FontName', 'Times');

if ~isempty(name)
    savefig([folder, name, '.fig']);
    saveas(f, [folder, name, '.png'])
close(f);
end


end