% Select visualization type: 'acuity' or 'contrast'
visualization_type = 'contrast';  % Change this to 'contrast' for contrast sensitivity plots

% Read both session files
data1 = readtable('../data/spreadsheet/session_1.csv', 'HeaderLines', 2);
data2 = readtable('../data/spreadsheet/session_2.csv', 'HeaderLines', 2);

% Get first n participants only
n_participants = 12;

if strcmp(visualization_type, 'acuity')
    % Chart Visual Acuity Data
    session1_right = data1.ETDRS_uncorr_R(1:n_participants);
    session2_right = data2.ETDRS_uncorr_R(1:n_participants);
    session1_left = data1.ETDRS_uncorr_L(1:n_participants);
    session2_left = data2.ETDRS_uncorr_L(1:n_participants);
    session1_bino = data1.ETDRS_uncorr_B(1:n_participants);
    session2_bino = data2.ETDRS_uncorr_B(1:n_participants);
    x_label = 'Session 1 Visual Acuity (logMAR)';
    y_label = 'Session 2 Visual Acuity (logMAR)';
    plot_title = 'Test-Retest: Chart Visual Acuity';
    axis_min = -0.3;
    axis_max = 1;
else
    % Chart Contrast Sensitivity Data
    session1_right = -abs(data1.Pelli_corr_R(1:n_participants));
    session2_right = -abs(data2.Pelli_corr_R(1:n_participants));
    session1_left = -abs(data1.Pelli_corr_L(1:n_participants));
    session2_left = -abs(data2.Pelli_corr_L(1:n_participants));
    session1_bino = -abs(data1.Pelli_corr_B(1:n_participants));
    session2_bino = -abs(data2.Pelli_corr_B(1:n_participants));
    
    % Add small random jitter to prevent overlap
    jitter_amount = 0.015;
    session1_right = session1_right + (rand(size(session1_right)) - 0.5) * jitter_amount;
    session2_right = session2_right + (rand(size(session2_right)) - 0.5) * jitter_amount;
    session1_left = session1_left + (rand(size(session1_left)) - 0.5) * jitter_amount;
    session2_left = session2_left + (rand(size(session2_left)) - 0.5) * jitter_amount;
    session1_bino = session1_bino + (rand(size(session1_bino)) - 0.5) * jitter_amount;
    session2_bino = session2_bino + (rand(size(session2_bino)) - 0.5) * jitter_amount;
    
    x_label = 'Session 1 Contrast Sensitivity (log units)';
    y_label = 'Session 2 Contrast Sensitivity (log units)';
    plot_title = 'Test-Retest: Chart Contrast Sensitivity';
    axis_min = -2.25;
    axis_max = -0.9;
end

% Create figure
figure('Position', [100 100 800 600]);

% Colors
right_color = 'r';
left_color = 'b';
bino_color = [0.5 0 0.5]; % purple

% Plot unity line
plot([axis_min axis_max], [axis_min axis_max], 'k--', 'LineWidth', 1);
hold on;

% Plot connecting lines between binocular and monocular measurements
for i = 1:length(session1_right)
    % Connect binocular to right eye
    plot([session1_bino(i) session1_right(i)], [session2_bino(i) session2_right(i)], ...
        'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    % Connect binocular to left eye
    plot([session1_bino(i) session1_left(i)], [session2_bino(i) session2_left(i)], ...
        'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
end

% Calculate R-squared values
r2_right = corr(session1_right, session2_right, 'rows', 'complete')^2;
r2_left = corr(session1_left, session2_left, 'rows', 'complete')^2;
r2_bino = corr(session1_bino, session2_bino, 'rows', 'complete')^2;

% Plot and fit right eye data
scatter(session1_right, session2_right, 50, right_color, 'filled', 'MarkerFaceAlpha', 0.7);
p_right = polyfit(session1_right, session2_right, 1);
plot([axis_min axis_max], polyval(p_right, [axis_min axis_max]), '--', 'Color', right_color, 'LineWidth', 2);

% Plot and fit left eye data
scatter(session1_left, session2_left, 50, left_color, 'filled', 'MarkerFaceAlpha', 0.7);
p_left = polyfit(session1_left, session2_left, 1);
plot([axis_min axis_max], polyval(p_left, [axis_min axis_max]), '--', 'Color', left_color, 'LineWidth', 2);

% Plot and fit binocular data
scatter(session1_bino, session2_bino, 50, bino_color, 'filled', 'MarkerFaceAlpha', 0.7);
p_bino = polyfit(session1_bino, session2_bino, 1);
plot([axis_min axis_max], polyval(p_bino, [axis_min axis_max]), '--', 'Color', bino_color, 'LineWidth', 2);

% Formatting
grid on;
xlabel(x_label);
ylabel(y_label);
title(plot_title);
axis([axis_min axis_max axis_min axis_max]);
axis square;

% Add legend with R² values
legend({sprintf('Right (R² = %.3f)', r2_right), ...
    sprintf('Left (R² = %.3f)', r2_left), ...
    sprintf('Binocular (R² = %.3f)', r2_bino), ...
    'Unity'}, ...
    'Location', 'southeast');

% Print correlation coefficients
fprintf('\nCorrelation Coefficients:\n');
fprintf('Right Eye: R = %.3f\n', corr(session1_right, session2_right, 'rows', 'complete'));
fprintf('Left Eye: R = %.3f\n', corr(session1_left, session2_left, 'rows', 'complete'));
fprintf('Binocular: R = %.3f\n', corr(session1_bino, session2_bino, 'rows', 'complete'));