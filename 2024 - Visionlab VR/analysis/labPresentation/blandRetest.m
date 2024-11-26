% Select visualization type: 'acuity' or 'contrast'
visualization_type = 'contrast';  % Change this to 'contrast' for contrast sensitivity plots

% Select method: 'vr' or 'chart'
method_type = 'chart';  % Change this to 'chart' for chart measurements

% Read both session files
data1 = readtable('../../data/spreadsheet/session_1.csv', 'HeaderLines', 2);
data2 = readtable('../../data/spreadsheet/session_2.csv', 'HeaderLines', 2);

% Get first 6 participants only
n_participants = 12;

if strcmp(visualization_type, 'acuity')
    if strcmp(method_type, 'vr')
        % VR Visual Acuity Data
        s1_R = data1.VR_acuity_uncorr_R(1:n_participants);
        s1_L = data1.VR_acuity_uncorr_L(1:n_participants);
        s1_B = data1.VR_acuity_uncorr_B(1:n_participants);

        s2_R = data2.VR_acuity_uncorr_R(1:n_participants);
        s2_L = data2.VR_acuity_uncorr_L(1:n_participants);
        s2_B = data2.VR_acuity_uncorr_B(1:n_participants);
        
        method_name = 'VR';
    else
        % Chart Visual Acuity Data
        s1_R = data1.ETDRS_uncorr_R(1:n_participants);
        s1_L = data1.ETDRS_uncorr_L(1:n_participants);
        s1_B = data1.ETDRS_uncorr_B(1:n_participants);

        s2_R = data2.ETDRS_uncorr_R(1:n_participants);
        s2_L = data2.ETDRS_uncorr_L(1:n_participants);
        s2_B = data2.ETDRS_uncorr_B(1:n_participants);
        
        method_name = 'Chart';
    end
    x_label = 'Mean of Sessions (logMAR)';
    y_label = 'Difference (Session 1 - Session 2)';
    plot_title = sprintf('Bland-Altman Plot: %s Visual Acuity Test-Retest', method_name);
else
    if strcmp(method_type, 'vr')
        % VR Contrast Sensitivity Data
        s1_R = -abs(data1.VR_cs_corr_R(1:n_participants));
        s1_L = -abs(data1.VR_cs_corr_L(1:n_participants));
        s1_B = -abs(data1.VR_cs_corr_B(1:n_participants));

        s2_R = -abs(data2.VR_cs_corr_R(1:n_participants));
        s2_L = -abs(data2.VR_cs_corr_L(1:n_participants));
        s2_B = -abs(data2.VR_cs_corr_B(1:n_participants));
        
        method_name = 'VR';
    else
        % Chart Contrast Sensitivity Data
        s1_R = -abs(data1.Pelli_corr_R(1:n_participants));
        s1_L = -abs(data1.Pelli_corr_L(1:n_participants));
        s1_B = -abs(data1.Pelli_corr_B(1:n_participants));

        s2_R = -abs(data2.Pelli_corr_R(1:n_participants));
        s2_L = -abs(data2.Pelli_corr_L(1:n_participants));
        s2_B = -abs(data2.Pelli_corr_B(1:n_participants));
        
        method_name = 'Chart';
    end
    x_label = 'Mean of Sessions (log units)';
    y_label = 'Difference (Session 1 - Session 2)';
    plot_title = sprintf('Bland-Altman Plot: %s Contrast Sensitivity Test-Retest', method_name);
end

% Remove any NaN pairs
valid_R = ~isnan(s1_R) & ~isnan(s2_R);
valid_L = ~isnan(s1_L) & ~isnan(s2_L);
valid_B = ~isnan(s1_B) & ~isnan(s2_B);

s1_R = s1_R(valid_R); s2_R = s2_R(valid_R);
s1_L = s1_L(valid_L); s2_L = s2_L(valid_L);
s1_B = s1_B(valid_B); s2_B = s2_B(valid_B);

% Calculate overall limits for consistent axes
all_means = [(s1_R + s2_R)/2; (s1_L + s2_L)/2; (s1_B + s2_B)/2];
all_diffs = [s1_R - s2_R; s1_L - s2_L; s1_B - s2_B];

if strcmp(visualization_type, 'acuity')
    % Fixed x-axis limits for acuity
    x_min = -0.3;
    x_max = 1.0;
else
    % Fixed limits for contrast
    x_min = -2.25;
    x_max = -1.0;
end

y_min = floor(min(all_diffs)*10)/10 - 0.2;  % Added extra space below
y_max = ceil(max(all_diffs)*10)/10 + 0.2;   % Added extra space above

% Create single figure instead of subplots
figure('Position', [100 100 800 600]);

% Colors for each condition
right_color = 'r';
left_color = 'b';
bino_color = [0.5 0 0.5]; % purple

% Create single Bland-Altman plot with all data points
createBlandAltmanPlot(s1_R, s2_R, 'Right Eye', right_color, ...
                      s1_L, s2_L, 'Left Eye', left_color, ...
                      s1_B, s2_B, 'Binocular', bino_color, ...
                      x_label, y_label, x_min, x_max, y_min, y_max, plot_title, ...
                      visualization_type, method_type);

% Replace the old helper function with this new one
function createBlandAltmanPlot(s1_R, s2_R, titleR, colorR, ...
                              s1_L, s2_L, titleL, colorL, ...
                              s1_B, s2_B, titleB, colorB, ...
                              x_label, y_label, x_min, x_max, y_min, y_max, plot_title, ...
                              visualization_type, method_type)
    % Calculate differences and means for each condition
    differences_R = s1_R - s2_R;
    means_R = (s1_R + s2_R) / 2;
    differences_L = s1_L - s2_L;
    means_L = (s1_L + s2_L) / 2;
    differences_B = s1_B - s2_B;
    means_B = (s1_B + s2_B) / 2;
    
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
    hold on;  % Add hold on here, at the start
    
    if strcmp(visualization_type, 'contrast') && strcmp(method_type, 'chart')
        % Add jitter for chart contrast condition
        jitter = 0.015;
        jitter_R = (rand(size(means_R)) - 0.5) * jitter;
        jitter_L = (rand(size(means_L)) - 0.5) * jitter;
        jitter_B = (rand(size(means_B)) - 0.5) * jitter;
        
        % Plot connecting lines first (behind the points)
        for i = 1:length(means_L)
            % Connect Left to Binocular
            plot([means_L(i)+jitter_L(i), means_B(i)+jitter_B(i)], ...
                 [differences_L(i)+jitter_L(i), differences_B(i)+jitter_B(i)], ...
                 '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
            % Connect Binocular to Right
            plot([means_B(i)+jitter_B(i), means_R(i)+jitter_R(i)], ...
                 [differences_B(i)+jitter_B(i), differences_R(i)+jitter_R(i)], ...
                 '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
        end
        
        % Plot points on top of lines
        scatter(means_R + jitter_R, differences_R + jitter_R, 100, colorR, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', titleR);
        scatter(means_L + jitter_L, differences_L + jitter_L, 100, colorL, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', titleL);
        scatter(means_B + jitter_B, differences_B + jitter_B, 100, colorB, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', titleB);
    else
        % Regular plotting for all other conditions
        % Plot connecting lines first
        for i = 1:length(means_L)
            % Connect Left to Binocular
            plot([means_L(i), means_B(i)], [differences_L(i), differences_B(i)], ...
                 '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
            % Connect Binocular to Right
            plot([means_B(i), means_R(i)], [differences_B(i), differences_R(i)], ...
                 '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
        end
        
        % Plot points on top of lines
        scatter(means_R, differences_R, 100, colorR, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', titleR);
        scatter(means_L, differences_L, 100, colorL, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', titleL);
        scatter(means_B, differences_B, 100, colorB, 'filled', 'MarkerFaceAlpha', 0.7, 'DisplayName', titleB);
    end
    
% Add reference lines with increased font size and line width
    yline(meanDiff, 'k-', sprintf('Mean = %.2f', meanDiff), 'LineWidth', 2, 'FontSize', 20);
    yline(upperLimit, 'k--', sprintf('+1.96 SD = %.2f', upperLimit), 'LineWidth', 2, 'FontSize', 20);
    yline(lowerLimit, 'k--', sprintf('-1.96 SD = %.2f', lowerLimit), 'LineWidth', 2, 'FontSize', 20);
    yline(0, 'k:', 'LineWidth', 2); % Zero line
    
    % Add Meta Quest reference lines only for acuity plots
    if strcmp(visualization_type, 'acuity')
        fontSize = 20;  % Match the font size of other labels
        yline(log10(30/10), '--', 'Meta Q2', 'LineWidth', 1, 'FontSize', fontSize, 'Color', [0.5 0.5 0.5]); % Quest 2
        yline(log10(30/12.5), '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', fontSize, 'Color', [0.5 0.5 0.5]); % Quest 3
    end
    
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
    
    % Print statistics
    fprintf('\nOverall Statistics:\n');
    fprintf('Mean difference: %.2f\n', meanDiff);
    fprintf('Standard deviation of differences: %.2f\n', sdDiff);
    fprintf('95%% Limits of agreement: (%.2f to %.2f)\n', lowerLimit, upperLimit);
end