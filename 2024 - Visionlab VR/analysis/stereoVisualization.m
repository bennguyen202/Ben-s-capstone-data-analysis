clear all
close all

% Requires psychtoolbox
% Install from Matlab → Home → Add-ons → Get Add-ons → Search for Psychtoolbox → Add

% Configuration
sub = '010';
experiment_type = 'contrast'; % Change to 'contrast' for contrast sensitivity
eccentricity = 5; % Only used for acuity
test_number = '01'; % Specify the test number

% Define the file names and directories
base_dir = ['../data/sub-' sub '/'];
if strcmp(experiment_type, 'acuity')
    data_dir = [base_dir 'acuity/'];
    file_name = sprintf('sub-%s_ecc-%d-%s.json', sub, eccentricity, test_number);
else
    data_dir = [base_dir 'contrast/'];
    file_name = sprintf('sub-%s_cs-%s.json', sub, test_number);
end

% Load the JSON data for the selected experiment
data = jsondecode(fileread([data_dir file_name]));

% Define eye conditions
eye_conditions = unique({data.EyeCondition});

% Set figure defaults
fontSize = 14;
set(groot,'defaultAxesFontSize', fontSize)
set(groot,'defaultTextFontSize', fontSize)
set(groot,'defaultLegendFontSize', fontSize)
set(groot,'defaultAxesLineWidth',1)
set(groot,'defaultLineLineWidth',2)
set(groot,'defaultAxesTickDir', 'out');
set(groot,'defaultAxesTickDirMode', 'manual');

% Define colors for each plot
colors = lines(length(eye_conditions)); % Use MATLAB's built-in colormap for distinct colors

% Create a single figure for all eye conditions
figure;
ax = gca;
hold on;

% Loop through each eye condition and plot the data
for j = 1:length(eye_conditions)
    % Filter data for the current eye condition
    eye_data = data(strcmp({data.EyeCondition}, eye_conditions{j}));
    
    % Extract trial numbers and the appropriate metric
    trial_numbers = 1:length(eye_data);
    if strcmp(experiment_type, 'acuity')
        values = arrayfun(@(entry) entry.LogMAR, eye_data);
    else
        values = arrayfun(@(entry) entry.LogLum, eye_data);
    end
    
    % Plot data for the current eye condition
    plot_data_with_line(ax, trial_numbers, values, colors(j, :), j, eccentricity, eye_conditions{j}, experiment_type);
end

% Add lines for Meta Q2 and Q3 if acuity
if strcmp(experiment_type, 'acuity')
    yline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1,'FontSize', fontSize); % Quest 2
    yline(log10(30/12.5),'--','Meta Q3', 'LineWidth',1,'FontSize', fontSize); % Quest 3
    ylim([0.3, 1.1]);
elseif strcmp(experiment_type, 'contrast')
    ylim([-2, 0]);
end
xlim([1, length(eye_data)]);

% Add title with subject number and test number
if strcmp(experiment_type, 'acuity')
    title(sprintf('Visual Acuity - Sub %s - Test %s', sub, test_number));
else
    title(sprintf('Contrast Sensitivity - Subject %s - Test %s', sub, test_number));
end

% Save the figure
exportgraphics(gcf, ['../figures/sub-' sub '_' experiment_type '_test_' test_number '_combined_single_axes.pdf']);

% Function to plot data and add a red horizontal line with annotation
function plot_data_with_line(ax, trial_numbers, values, color, index, ecc_number, eye_condition, experiment_type)
    plot(ax, trial_numbers, values, 'o-', 'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color, 'Color', color); % Smaller, colored circles

    num_final_values = 20;
    if length(values) >= num_final_values
        avg_final_values = mean(values(end-num_final_values+1:end));
    else
        avg_final_values = mean(values); % Use all available values if fewer than 20
    end

    fontSize = 14;

    % Plot the red dashed line at the average
    yline(ax, avg_final_values, 'r--', 'Color', color);

    % Add text annotation at the top right of the figure, offset by index
    if strcmp(experiment_type, 'acuity')
        annotation('textbox', [0.8, 0.85 - 0.05 * index, 0.1, 0.1], 'String', sprintf('Threshold (%s, %d deg): %.2f logMAR', eye_condition, ecc_number, avg_final_values), ...
            'EdgeColor', 'none', 'Color', color, 'FontSize', fontSize, 'HorizontalAlignment', 'right');
        ylabel(ax, 'Visual Acuity (LogMAR)');
    else
        annotation('textbox', [0.8, 0.85 - 0.05 * index, 0.1, 0.1], 'String', sprintf('Threshold (%s): %.2f LogLum', eye_condition, avg_final_values), ...
            'EdgeColor', 'none', 'Color', color, 'FontSize', fontSize, 'HorizontalAlignment', 'right');
        ylabel(ax, 'Log Luminance');
    end

    xlabel(ax, 'Trial Number');
    ax.Box = 'off';  % Remove top and right border
end