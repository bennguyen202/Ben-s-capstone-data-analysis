% Read both session files
data1 = readtable('../../data/spreadsheet/session_1.csv', 'HeaderLines', 2);
data2 = readtable('../../data/spreadsheet/session_2.csv', 'HeaderLines', 2);

% Get first n participants only
n_participants = 12;

% Extract Visual Acuity data (ETDRS uncorrected) for both sessions
% Session 1
right_s1 = data1.ETDRS_uncorr_R(1:n_participants);
left_s1 = data1.ETDRS_uncorr_L(1:n_participants);
bino_s1 = data1.ETDRS_uncorr_B(1:n_participants);

% Session 2
right_s2 = data2.ETDRS_uncorr_R(1:n_participants);
left_s2 = data2.ETDRS_uncorr_L(1:n_participants);
bino_s2 = data2.ETDRS_uncorr_B(1:n_participants);

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
x_range = linspace(-0.3, 1.0, 100);  % Updated range
plot(x_range, polyval(p_right, x_range), 'r--');
plot(x_range, polyval(p_left, x_range), 'b--');
plot(x_range, polyval(p_bino, x_range), 'Color', [0.5 0 0.5], 'LineStyle', '--'); 

% Set both axes to range from -0.3 to 0.9
xlim([-0.1 0.9]);
ylim([-0.1 0.9]);

% Add unity line covering the new range
plot([-0.3 1.0], [-0.3 1.0], 'k--', 'LineWidth', 2);

% Add legend with R² values
legend({sprintf('Right Eye (R² = %.3f)', r2_right), ...
        sprintf('Left Eye (R² = %.3f)', r2_left), ...
        sprintf('Binocular (R² = %.3f)', r2_bino), ...
        'Right Eye Trend', 'Left Eye Trend', 'Binocular Trend', ...
        'Unity Line'}, ...
        'Location', 'southeast');

% Labels and title
xlabel('Session 1 Visual Acuity (logMAR)');
ylabel('Session 2 Visual Acuity (logMAR)');
title('Test-Retest Reliability of Visual Acuity Measurements (ETDRS Chart)');
grid on;

% Make axes equal and set limits
axis equal;
%xlim([min([right_s1; left_s1; bino_s1])-0.1 max([right_s1; left_s1; bino_s1])+0.1]);
%ylim([min([right_s2; left_s2; bino_s2])-0.1 max([right_s2; left_s2; bino_s2])+0.1]);