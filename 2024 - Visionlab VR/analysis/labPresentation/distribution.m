% Select visualization type: 'acuity' or 'contrast'
visualization_type = 'contrast';  % Change this to 'contrast' for contrast sensitivity plots

% Select method: 'vr' or 'chart'
method_type = 'chart';  % Change this to 'chart' for chart measurements

% Read both session files
data1 = readtable('../../data/spreadsheet/session_1.csv', 'HeaderLines', 2);
data2 = readtable('../../data/spreadsheet/session_2.csv', 'HeaderLines', 2);

% Get first n participants only
n_participants = 12;

if strcmp(visualization_type, 'acuity')
    if strcmp(method_type, 'vr')
        % VR Visual Acuity Data
        right_data = [data1.VR_acuity_uncorr_R(1:n_participants); data2.VR_acuity_uncorr_R(1:n_participants)];
        left_data = [data1.VR_acuity_uncorr_L(1:n_participants); data2.VR_acuity_uncorr_L(1:n_participants)];
        bino_data = [data1.VR_acuity_uncorr_B(1:n_participants); data2.VR_acuity_uncorr_B(1:n_participants)];
        method_name = 'VR';
        bin_width = 0.02;  % Smaller bins for acuity (0.02 logMAR)
    else
        % Chart Visual Acuity Data
        right_data = [data1.ETDRS_uncorr_R(1:n_participants); data2.ETDRS_uncorr_R(1:n_participants)];
        left_data = [data1.ETDRS_uncorr_L(1:n_participants); data2.ETDRS_uncorr_L(1:n_participants)];
        bino_data = [data1.ETDRS_uncorr_B(1:n_participants); data2.ETDRS_uncorr_B(1:n_participants)];
        method_name = 'Chart';
        bin_width = 0.02;  % Smaller bins for acuity (0.02 logMAR)
    end
    x_label = 'Visual Acuity (logMAR)';
    plot_title = sprintf('Distribution of %s Visual Acuity Measurements (Both Sessions)', method_name);
else
    if strcmp(method_type, 'vr')
        % VR Contrast Sensitivity Data
        right_data = -abs([data1.VR_cs_corr_R(1:n_participants); data2.VR_cs_corr_R(1:n_participants)]);
        left_data = -abs([data1.VR_cs_corr_L(1:n_participants); data2.VR_cs_corr_L(1:n_participants)]);
        bino_data = -abs([data1.VR_cs_corr_B(1:n_participants); data2.VR_cs_corr_B(1:n_participants)]);
        method_name = 'VR';
        x_label = 'Contrast Sensitivity (log units)';
        bin_width = 0.05;  % Smaller bins for contrast sensitivity (0.05 log units)
    else
        % Chart Contrast Sensitivity Data
        right_data = -abs([data1.Pelli_corr_R(1:n_participants); data2.Pelli_corr_R(1:n_participants)]);
        left_data = -abs([data1.Pelli_corr_L(1:n_participants); data2.Pelli_corr_L(1:n_participants)]);
        bino_data = -abs([data1.Pelli_corr_B(1:n_participants); data2.Pelli_corr_B(1:n_participants)]);
        method_name = 'Chart';
        x_label = 'Contrast Sensitivity (log units)';
        bin_width = 0.05;  % Smaller bins for contrast sensitivity (0.05 log units)
    end
    
    plot_title = sprintf('Distribution of %s Contrast Sensitivity Measurements (Both Sessions)', method_name);
end

% Remove NaN values
right_data = right_data(~isnan(right_data));
left_data = left_data(~isnan(left_data));
bino_data = bino_data(~isnan(bino_data));

% Calculate overall limits for consistent axes
all_data = [right_data; left_data; bino_data];
x_min = floor(min(all_data)*20)/20;  % Round to nearest 0.05
x_max = ceil(max(all_data)*20)/20;   % Round to nearest 0.05

% Calculate bin edges
bin_edges = x_min:bin_width:x_max;

% Calculate max count for consistent y-axis
max_count = max([histcounts(right_data, bin_edges), ...
                histcounts(left_data, bin_edges), ...
                histcounts(bino_data, bin_edges)]);

% Create figure
figure('Position', [100 100 600 1000]);

% Colors for each condition
right_color = 'r';
left_color = 'b';
bino_color = [0.5 0 0.5]; % purple

if strcmp(visualization_type, 'acuity')
    % Fixed x-axis limits for acuity
    x_min = -0.3;
    x_max = 1.0;
else
    % Different limits based on method type for contrast
    if strcmp(method_type, 'vr')
        % Fixed x-axis limits for VR contrast
        x_min = -2.25;  % Adjust this value as needed
        x_max = -0.9;   % Adjust this value as needed
    else
        % Fixed x-axis limits for chart contrast
        x_min = -2.25;
        x_max = -0.9;
    end
end

% Calculate bin edges with new limits
bin_edges = x_min:bin_width:x_max;

% Right Eye
subplot(3,1,1);
histogram(right_data, bin_edges, 'FaceColor', right_color, 'FaceAlpha', 0.7);
hold on;
xline(mean(right_data), '--k', 'Mean', 'LineWidth', 1.5, 'FontSize', 20);
title('Right Eye');
xlabel(x_label);
ylabel('Frequency');
xlim([x_min x_max]);
ylim([0 max_count + 1]);
grid on;
text(0.02, 0.95, sprintf('Mean = %.2f\nSD = %.2f', mean(right_data), std(right_data)), ...
    'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');

% Left Eye
subplot(3,1,2);
histogram(left_data, bin_edges, 'FaceColor', left_color, 'FaceAlpha', 0.7);
hold on;
xline(mean(left_data), '--k', 'Mean', 'LineWidth', 1.5, 'FontSize', 20);
title('Left Eye');
xlabel(x_label);
ylabel('Frequency');
xlim([x_min x_max]);
ylim([0 max_count + 1]);
grid on;
text(0.02, 0.95, sprintf('Mean = %.2f\nSD = %.2f', mean(left_data), std(left_data)), ...
    'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');

% Binocular
subplot(3,1,3);
histogram(bino_data, bin_edges, 'FaceColor', bino_color, 'FaceAlpha', 0.7);
hold on;
xline(mean(bino_data), '--k', 'Mean', 'LineWidth', 1.5, 'FontSize', 20);
title('Binocular');
xlabel(x_label);
ylabel('Frequency');
xlim([x_min x_max]);
ylim([0 max_count + 1]);
grid on;
text(0.02, 0.95, sprintf('Mean = %.2f\nSD = %.2f', mean(bino_data), std(bino_data)), ...
    'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');

% Overall title
sgtitle(plot_title, 'FontSize', 14);

% Print overall statistics
fprintf('\n%s %s Statistics:\n', method_name, visualization_type);
fprintf('Right Eye: Mean = %.2f, SD = %.2f\n', mean(right_data), std(right_data));
fprintf('Left Eye: Mean = %.2f, SD = %.2f\n', mean(left_data), std(left_data));
fprintf('Binocular: Mean = %.2f, SD = %.2f\n', mean(bino_data), std(bino_data));