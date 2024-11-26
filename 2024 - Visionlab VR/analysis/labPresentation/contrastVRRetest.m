% Read both session files
data1 = readtable('../../data/spreadsheet/session_1.csv', 'HeaderLines', 2);
data2 = readtable('../../data/spreadsheet/session_2.csv', 'HeaderLines', 2);

% Get first n participants only
n_participants = 12;

% Extract VR Contrast Sensitivity data for both sessions
% Session 1
right_s1 = data1.VR_cs_corr_R(1:n_participants);
left_s1 = data1.VR_cs_corr_L(1:n_participants);
bino_s1 = data1.VR_cs_corr_B(1:n_participants);

% Session 2
right_s2 = data2.VR_cs_corr_R(1:n_participants);
left_s2 = data2.VR_cs_corr_L(1:n_participants);
bino_s2 = data2.VR_cs_corr_B(1:n_participants);

% Remove any NaN values
valid_idx = ~isnan(right_s1) & ~isnan(right_s2) & ~isnan(left_s1) & ...
           ~isnan(left_s2) & ~isnan(bino_s1) & ~isnan(bino_s2);
right_s1 = right_s1(valid_idx);
right_s2 = right_s2(valid_idx);
left_s1 = left_s1(valid_idx);
left_s2 = left_s2(valid_idx);
bino_s1 = bino_s1(valid_idx);
bino_s2 = bino_s2(valid_idx);

% Create figure
figure;
hold on;

% Plot connecting lines first (behind the points)
for i = 1:length(left_s1)
    % Connect Left to Binocular
    plot([left_s1(i), bino_s1(i)], [left_s2(i), bino_s2(i)], ...
         '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
    % Connect Binocular to Right
    plot([bino_s1(i), right_s1(i)], [bino_s2(i), right_s2(i)], ...
         '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
end

% Plot each condition and calculate R²
% Right Eye (Red)
scatter(right_s1, right_s2, 100, 'r', 'filled', 'MarkerFaceAlpha', 0.7);
p_right = polyfit(right_s1, right_s2, 1);
r2_right = corrcoef(right_s1, right_s2);
r2_right = r2_right(1,2)^2;

% Left Eye (Blue)
scatter(left_s1, left_s2, 100, 'b', 'filled', 'MarkerFaceAlpha', 0.7);
p_left = polyfit(left_s1, left_s2, 1);
r2_left = corrcoef(left_s1, left_s2);
r2_left = r2_left(1,2)^2;

% Binocular (Purple)
scatter(bino_s1, bino_s2, 100, [0.5 0 0.5], 'filled', 'MarkerFaceAlpha', 0.7);
p_bino = polyfit(bino_s1, bino_s2, 1);
r2_bino = corrcoef(bino_s1, bino_s2);
r2_bino = r2_bino(1,2)^2;

% Add trend lines
x_range = linspace(-1.7, -0.9, 100);  % Modified x_range
plot(x_range, polyval(p_right, x_range), 'r--');
plot(x_range, polyval(p_left, x_range), 'b--');
plot(x_range, polyval(p_bino, x_range), 'Color', [0.5 0 0.5], 'LineStyle', '--');

% Add unity line with new range and increased width
plot([-1.7 -0.9], [-1.7 -0.9], 'k--', 'LineWidth', 2);

% Add legend with R² values
legend({sprintf('Right Eye (R² = %.3f)', r2_right), ...
        sprintf('Left Eye (R² = %.3f)', r2_left), ...
        sprintf('Binocular (R² = %.3f)', r2_bino), ...
        'Right Eye Trend', 'Left Eye Trend', 'Binocular Trend', ...
        'Unity Line'}, ...
        'Location', 'southeast', ...
        'FontSize', 8);  % Added FontSize parameter

% Labels and title
xlabel('Session 1 Contrast Sensitivity (log units)');
ylabel('Session 2 Contrast Sensitivity (log units)');
title('Test-Retest Reliability of Contrast Sensitivity Measurements (VR)');
grid on;

% Make axes equal and set fixed limits
axis equal;
xlim([-1.7 -0.9]);
ylim([-1.7 -0.9]);