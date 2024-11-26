% Select visualization type: 'acuity' or 'contrast'
visualization_type = 'acuity';  % Change this to 'contrast' for contrast sensitivity plots

% Read both session files
data1 = readtable('../../data/spreadsheet/session_1.csv', 'HeaderLines', 2);
data2 = readtable('../../data/spreadsheet/session_2.csv', 'HeaderLines', 2);

% Get first n participants only
n_participants = 12;

if strcmp(visualization_type, 'acuity')
    % Visual Acuity Data
    chart_R = [data1.ETDRS_uncorr_R(1:n_participants); data2.ETDRS_uncorr_R(1:n_participants)];
    chart_L = [data1.ETDRS_uncorr_L(1:n_participants); data2.ETDRS_uncorr_L(1:n_participants)];
    chart_B = [data1.ETDRS_uncorr_B(1:n_participants); data2.ETDRS_uncorr_B(1:n_participants)];

    vr_R = [data1.VR_acuity_uncorr_R(1:n_participants); data2.VR_acuity_uncorr_R(1:n_participants)];
    vr_L = [data1.VR_acuity_uncorr_L(1:n_participants); data2.VR_acuity_uncorr_L(1:n_participants)];
    vr_B = [data1.VR_acuity_uncorr_B(1:n_participants); data2.VR_acuity_uncorr_B(1:n_participants)];
    
    x_label = 'Mean of Chart and VR (logMAR)';
    y_label = 'Difference (Chart - VR)';
    plot_title = 'Bland-Altman Plot: Chart vs VR Visual Acuity (Both Sessions)';
else
    % Contrast Sensitivity Data
    chart_R = [data1.Pelli_corr_R(1:n_participants); data2.Pelli_corr_R(1:n_participants)];
    chart_L = [data1.Pelli_corr_L(1:n_participants); data2.Pelli_corr_L(1:n_participants)];
    chart_B = [data1.Pelli_corr_B(1:n_participants); data2.Pelli_corr_B(1:n_participants)];

    % Add abs() function to make VR contrast values positive
    vr_R = abs([data1.VR_cs_corr_R(1:n_participants); data2.VR_cs_corr_R(1:n_participants)]);
    vr_L = abs([data1.VR_cs_corr_L(1:n_participants); data2.VR_cs_corr_L(1:n_participants)]);
    vr_B = abs([data1.VR_cs_corr_B(1:n_participants); data2.VR_cs_corr_B(1:n_participants)]);
    
    x_label = 'Mean of Chart and VR (log units)';
    y_label = 'Difference (Chart - VR)';
    plot_title = 'Bland-Altman Plot: Chart vs VR Contrast Sensitivity (Both Sessions)';
end

% Remove any NaN pairs
valid_R = ~isnan(chart_R) & ~isnan(vr_R);
valid_L = ~isnan(chart_L) & ~isnan(vr_L);
valid_B = ~isnan(chart_B) & ~isnan(vr_B);

chart_R = chart_R(valid_R); vr_R = vr_R(valid_R);
chart_L = chart_L(valid_L); vr_L = vr_L(valid_L);
chart_B = chart_B(valid_B); vr_B = vr_B(valid_B);

% Calculate overall limits for consistent axes
all_means = [(chart_R + vr_R)/2; (chart_L + vr_L)/2; (chart_B + vr_B)/2];
all_diffs = [chart_R - vr_R; chart_L - vr_L; chart_B - vr_B];

x_min = floor(min(all_means)*10)/10;
x_max = ceil(max(all_means)*10)/10;
y_min = floor(min(all_diffs)*10)/10;
y_max = ceil(max(all_diffs)*10)/10;

% Create single figure instead of subplots
figure('Position', [100 100 800 600]);

% Colors for each condition
right_color = 'r';
left_color = 'b';
bino_color = [0.5 0 0.5]; % purple

% Create single Bland-Altman plot with all data points
createBlandAltmanPlot(chart_R, vr_R, 'Right Eye', right_color, ...
                      chart_L, vr_L, 'Left Eye', left_color, ...
                      chart_B, vr_B, 'Binocular', bino_color, ...
                      x_label, y_label, x_min, x_max, y_min, y_max, plot_title, ...
                      visualization_type);

% Replace the helper function with this new one
function createBlandAltmanPlot(chart_R, vr_R, titleR, colorR, ...
                              chart_L, vr_L, titleL, colorL, ...
                              chart_B, vr_B, titleB, colorB, ...
                              x_label, y_label, x_min, x_max, y_min, y_max, plot_title, ...
                              visualization_type)
    % Calculate differences and means for each condition
    differences_R = chart_R - vr_R;
    means_R = (chart_R + vr_R) / 2;
    differences_L = chart_L - vr_L;
    means_L = (chart_L + vr_L) / 2;
    differences_B = chart_B - vr_B;
    means_B = (chart_B + vr_B) / 2;
    
    % Combine all differences for overall statistics
    all_differences = [differences_R; differences_L; differences_B];
    
    % Calculate overall mean difference and standard deviation
    meanDiff = mean(all_differences);
    sdDiff = std(all_differences);
    
    % Calculate limits of agreement
    upperLimit = meanDiff + 1.96 * sdDiff;
    lowerLimit = meanDiff - 1.96 * sdDiff;
    
    % Create the main plot
    ax1 = gca;
    scatter(means_R, differences_R, 100, colorR, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', titleR);
    hold on;
    scatter(means_L, differences_L, 100, colorL, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', titleL);
    scatter(means_B, differences_B, 100, colorB, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', titleB);
    
    % Add reference lines with increased font size and line width
    yline(meanDiff, 'k-', sprintf('Mean = %.2f', meanDiff), 'LineWidth', 2, 'FontSize', 20);
    yline(upperLimit, 'k--', sprintf('+1.96 SD = %.2f', upperLimit), 'LineWidth', 2, 'FontSize', 20);
    yline(lowerLimit, 'k--', sprintf('-1.96 SD = %.2f', lowerLimit), 'LineWidth', 2, 'FontSize', 20);
    yline(0, 'k:', 'LineWidth', 2); % Zero line
    
    % Set axes limits
    xlim([x_min x_max]);
    ylim([y_min y_max]);
    
    % Labels and title for main axis
    xlabel(x_label);
    ylabel(y_label);
    title(plot_title, 'FontSize', 20);
    grid on;
    legend('Location', 'best');
    
    % Print statistics
    fprintf('\nOverall Statistics:\n');
    fprintf('Mean difference: %.2f\n', meanDiff);
    fprintf('Standard deviation of differences: %.2f\n', sdDiff);
    fprintf('95%% Limits of agreement: (%.2f to %.2f)\n', lowerLimit, upperLimit);
end