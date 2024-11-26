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
% fontsize("default")
% fontsize(scale=1.2)

% Initialize arrays to store thresholds for each eye condition
thresholds.Left = [];
thresholds.Right = [];
thresholds.Both = [];

% Define colors for each histogram
colors = lines(3); % Use MATLAB's built-in colormap for distinct colors

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

        % Loop through each eye condition and calculate thresholds
        eye_conditions = {'Left', 'Right', 'Both'};
        for j = 1:length(eye_conditions)
            % Filter data for the current eye condition
            eye_data = acuity_data(strcmp({acuity_data.EyeCondition}, eye_conditions{j}));

            if isempty(eye_data)
                continue;
            end

            % Calculate the average threshold of the final 5 trials
            if length(eye_data) >= 5
                avg_final_values = mean(arrayfun(@(entry) entry.LogMAR, eye_data(end-4:end)));
                thresholds.(eye_conditions{j}) = [thresholds.(eye_conditions{j}), avg_final_values];
            end
        end
    end
end

% Create a figure with three subplots for histograms
% figureWidth = 1200; % Set desired width in pixels
% figureHeight = 400; % Set desired height in pixels
% figure('Position', [100, 100, figureWidth, figureHeight]); % Adjust the position and size

% Plot histograms for each eye condition
for k = 1:3
    ax(k) = subplot(3, 1, k);
    hold(ax(k), 'on');

    xline(ax(k), log10(30/12.5), '--', 'Quest 3', 'LineWidth', 1, 'FontSize', fontSize-4);
    xline(log10(30/10),'--', 'Quest 2', 'LineWidth',1, 'FontSize', fontSize-4);
    
    eye_condition = eye_conditions{k};
    histogram(ax(k), thresholds.(eye_condition), 'BinWidth', .025, 'FaceColor', colors(k, :));
    ax(k).XLim = [.2 2]; % temporary hack
    title(ax(k), [eye_condition ' Eye']);
    xlabel(ax(k), 'Threshold (LogMAR)');
    ylabel(ax(k), 'Frequency');  
end

% Save the figure
exportgraphics(gcf, '../figures/Macedonia_figures/acuity_combined_three_panels.pdf');