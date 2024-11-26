clear all
close all

% Configuration
base_dir = '../data/webdata/';
experiment_type = 'acuity'; % Only plot acuity data

% Get list of participant folders
participant_folders = dir(base_dir);
participant_folders = participant_folders([participant_folders.isdir] & ~ismember({participant_folders.name}, {'.', '..'}));

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
colors = lines(3); % Use MATLAB's built-in colormap for distinct colors

% Create a figure with three subplots for each eye condition
% figureWidth = 1200; % Set desired width in pixels
% figureHeight = 400; % Set desired height in pixels
% figure('Position', [100, 100, figureWidth, figureHeight]); % Adjust the position and size

eye_conditions = {'Left', 'Right', 'Both'};
for k = 1:3
    ax(k) = subplot(1, 3, k);
    hold(ax(k), 'on');
    title(ax(k), eye_conditions{k});
    xlabel(ax(k), 'Trial Number');
    ylabel(ax(k), 'Visual Acuity (LogMAR)');
    
    % Add the Meta Q3 and Q2 line to each subplot
    yline(ax(k), log10(30/12.5), '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', fontSize);
    yline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1,'FontSize', fontSize);
end

% Initialize variables to track global min and max for axes
globalMinX = inf;
globalMaxX = -inf;
globalMinY = inf;
globalMaxY = -inf;

% Iterate over each participant folder
for p = 1:length(participant_folders)
    participant_id = participant_folders(p).name;
    data_files = dir(fullfile(base_dir, participant_id, '*.json'));

    % Iterate over each data file
    for f = 1:length(data_files)
        file_path = fullfile(data_files(f).folder, data_files(f).name);
        data = jsondecode(fileread(file_path));

        % Filter data for acuity test type
        acuity_data = data(strcmp({data.TestType}, 'Acuity'));

        % Loop through each eye condition and plot the data
        for j = 1:length(eye_conditions)
            % Filter data for the current eye condition
            eye_data = acuity_data(strcmp({acuity_data.EyeCondition}, eye_conditions{j}));

            if isempty(eye_data)
                continue;
            end

            % Extract trial numbers and LogMAR values
            trial_numbers = 1:length(eye_data);
            values = arrayfun(@(entry) entry.LogMAR, eye_data);

            % Plot data for the current eye condition
            plot(ax(j), trial_numbers, values, 'o-', 'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', colors(j, :), 'Color', colors(j, :));

            % Calculate and plot the average of the final 5 trials
            if length(values) >= 5
                avg_final_values = mean(values(end-4:end));
                yline(ax(j), avg_final_values, 'r--', 'Color', colors(j, :));
            end

            % Update global min and max for axes
            globalMinX = min(globalMinX, min(trial_numbers));
            globalMaxX = max(globalMaxX, max(trial_numbers));
            globalMinY = min(globalMinY, min(values));
            globalMaxY = max(globalMaxY, max(values));
        end
    end
end

% Set the same x and y limits for all subplots
for k = 1:3
    % xlim(ax(k), [globalMinX, globalMaxX]);
    % ylim(ax(k), [globalMinY, globalMaxY]);
    % temporary hack
    ylim([.2 2])
end

% Save the figure
exportgraphics(gcf, '../figures/Macedonia_figures/acuity_combined_three_panels.pdf');