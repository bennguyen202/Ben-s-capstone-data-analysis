% Select visualization type: 'acuity' or 'contrast'
visualization_type = 'acuity';  % Change this to 'contrast' for contrast sensitivity plots

% Read both session files
data1 = readtable('../../data/spreadsheet/session_1.csv', 'HeaderLines', 2);
data2 = readtable('../../data/spreadsheet/session_2.csv', 'HeaderLines', 2);

% Get first n participants only
n_participants = 12;

if strcmp(visualization_type, 'acuity')
    % Visual Acuity Data
    % Session 1
    chart_R = data1.ETDRS_uncorr_R(1:n_participants);
    chart_L = data1.ETDRS_uncorr_L(1:n_participants);
    chart_B = data1.ETDRS_uncorr_B(1:n_participants);
    vr_R = data1.VR_acuity_uncorr_R(1:n_participants);
    vr_L = data1.VR_acuity_uncorr_L(1:n_participants);
    vr_B = data1.VR_acuity_uncorr_B(1:n_participants);
    
    % Session 2
    chart_R = [chart_R; data2.ETDRS_uncorr_R(1:n_participants)];
    chart_L = [chart_L; data2.ETDRS_uncorr_L(1:n_participants)];
    chart_B = [chart_B; data2.ETDRS_uncorr_B(1:n_participants)];
    vr_R = [vr_R; data2.VR_acuity_uncorr_R(1:n_participants)];
    vr_L = [vr_L; data2.VR_acuity_uncorr_L(1:n_participants)];
    vr_B = [vr_B; data2.VR_acuity_uncorr_B(1:n_participants)];
    
    x_label = 'Chart Visual Acuity (logMAR)';
    y_label = 'VR Visual Acuity (logMAR)';
    plot_title = 'Chart vs VR Visual Acuity Measurements (Both Sessions)';
else
     % Contrast Sensitivity Data
    % Session 1
    chart_R = data1.Pelli_corr_R(1:n_participants);
    chart_L = data1.Pelli_corr_L(1:n_participants);
    chart_B = data1.Pelli_corr_B(1:n_participants);
    vr_R = abs(data1.VR_cs_corr_R(1:n_participants));  % Convert to positive
    vr_L = abs(data1.VR_cs_corr_L(1:n_participants));  % Convert to positive
    vr_B = abs(data1.VR_cs_corr_B(1:n_participants));  % Convert to positive
    
    % Session 2
    chart_R = [chart_R; data2.Pelli_corr_R(1:n_participants)];
    chart_L = [chart_L; data2.Pelli_corr_L(1:n_participants)];
    chart_B = [chart_B; data2.Pelli_corr_B(1:n_participants)];
    vr_R = [vr_R; abs(data2.VR_cs_corr_R(1:n_participants))];  % Convert to positive
    vr_L = [vr_L; abs(data2.VR_cs_corr_L(1:n_participants))];  % Convert to positive
    vr_B = [vr_B; abs(data2.VR_cs_corr_B(1:n_participants))];  % Convert to positive
    
    x_label = 'Chart Contrast Sensitivity (log units)';
    y_label = 'VR Contrast Sensitivity (log units)';
    plot_title = 'Chart vs VR Contrast Sensitivity Measurements (Both Sessions)';
end

% Remove any NaN pairs
valid_R = ~isnan(chart_R) & ~isnan(vr_R);
valid_L = ~isnan(chart_L) & ~isnan(vr_L);
valid_B = ~isnan(chart_B) & ~isnan(vr_B);

chart_R = chart_R(valid_R); vr_R = vr_R(valid_R);
chart_L = chart_L(valid_L); vr_L = vr_L(valid_L);
chart_B = chart_B(valid_B); vr_B = vr_B(valid_B);

% Calculate overall limits for consistent axes
all_min = floor(min([chart_R; chart_L; chart_B; vr_R; vr_L; vr_B])*10)/10;
all_max = ceil(max([chart_R; chart_L; chart_B; vr_R; vr_L; vr_B])*10)/10;

% Create figure
figure('Position', [100 100 800 800]);

% Colors for each condition
right_color = 'r';
left_color = 'b';
bino_color = [0.5 0 0.5]; % purple

% Plot all data points
hold on;

% Plot connecting lines first (behind the points)
for i = 1:length(chart_L)
    % Connect Left to Binocular
    plot([chart_L(i), chart_B(i)], [vr_L(i), vr_B(i)], ...
         '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
    % Connect Binocular to Right
    plot([chart_B(i), chart_R(i)], [vr_B(i), vr_R(i)], ...
         '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
end

% Right Eye
scatter(chart_R, vr_R, 100, right_color, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', 'Right Eye');
p_R = polyfit(chart_R, vr_R, 1);
r_R = corrcoef(chart_R, vr_R);
r2_R = r_R(1,2)^2;

% Left Eye
scatter(chart_L, vr_L, 100, left_color, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', 'Left Eye');
p_L = polyfit(chart_L, vr_L, 1);
r_L = corrcoef(chart_L, vr_L);
r2_L = r_L(1,2)^2;

% Binocular
scatter(chart_B, vr_B, 100, bino_color, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', 'Binocular');
p_B = polyfit(chart_B, vr_B, 1);
r_B = corrcoef(chart_B, vr_B);
r2_B = r_B(1,2)^2;

% Add unity line
plot([all_min all_max], [all_min all_max], 'k--', 'DisplayName', 'Unity Line');

% Add trend lines
x_trend = linspace(all_min, all_max, 100);
plot(x_trend, polyval(p_R, x_trend), '--', 'Color', right_color, 'DisplayName', sprintf('Right Eye Trend (R² = %.3f)', r2_R));
plot(x_trend, polyval(p_L, x_trend), '--', 'Color', left_color, 'DisplayName', sprintf('Left Eye Trend (R² = %.3f)', r2_L));
plot(x_trend, polyval(p_B, x_trend), '--', 'Color', bino_color, 'DisplayName', sprintf('Binocular Trend (R² = %.3f)', r2_B));

% Set axes and labels
xlim([all_min all_max]);
ylim([all_min all_max]);
axis square;
xlabel(x_label);
ylabel(y_label);
title(plot_title);
grid on;

% Add legend
legend('Location', 'best', 'FontSize', 8);

% Print statistics
fprintf('\nRight Eye:\n');
fprintf('R² = %.3f\n', r2_R);
fprintf('Slope = %.3f\n', p_R(1));
fprintf('Intercept = %.3f\n\n', p_R(2));

fprintf('Left Eye:\n');
fprintf('R² = %.3f\n', r2_L);
fprintf('Slope = %.3f\n', p_L(1));
fprintf('Intercept = %.3f\n\n', p_L(2));

fprintf('Binocular:\n');
fprintf('R² = %.3f\n', r2_B);
fprintf('Slope = %.3f\n', p_B(1));
fprintf('Intercept = %.3f\n', p_B(2));