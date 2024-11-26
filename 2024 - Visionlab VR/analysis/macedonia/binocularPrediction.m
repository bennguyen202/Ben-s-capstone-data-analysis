clear all
close all

% Configuration
base_dir = '../data/webdata/';
experiment_type = 'acuity'; % Only plot acuity data

% Figure formatting
fontSize = 14; 

% Get list of participant folders
participant_folders = dir(base_dir);
participant_folders = participant_folders([participant_folders.isdir] & ~ismember({participant_folders.name}, {'.', '..'}));

% Initialize arrays to store data
left_eye_data = [];
right_eye_data = [];
binocular_data = [];

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

        % Extract data for each eye condition
        left_data = acuity_data(strcmp({acuity_data.EyeCondition}, 'Left'));
        right_data = acuity_data(strcmp({acuity_data.EyeCondition}, 'Right'));
        both_data = acuity_data(strcmp({acuity_data.EyeCondition}, 'Both'));

        % Calculate average LogMAR for the last 5 trials
        if length(left_data) >= 5 && length(right_data) >= 5 && length(both_data) >= 5
            left_avg = mean(arrayfun(@(entry) entry.LogMAR, left_data(end-4:end)));
            right_avg = mean(arrayfun(@(entry) entry.LogMAR, right_data(end-4:end)));
            both_avg = mean(arrayfun(@(entry) entry.LogMAR, both_data(end-4:end)));

            % Exclude data with LogMAR > 1
            if left_avg <= 1 && right_avg <= 1 && both_avg <= 1
                left_eye_data = [left_eye_data, left_avg];
                right_eye_data = [right_eye_data, right_avg];
                binocular_data = [binocular_data, both_avg];
            end
        end
    end
end

% Calculate predictions
mean_prediction = (left_eye_data + right_eye_data) / 2;
min_prediction = min(left_eye_data, right_eye_data);

% Determine global min and max for axes
all_x_data = [mean_prediction, min_prediction, left_eye_data, right_eye_data];
all_y_data = binocular_data;
% globalMin = min([all_x_data, all_y_data]);
% globalMax = max([all_x_data, all_y_data]);
globalMin = .3;
globalMax = 1; 

% Create a figure with four subplots
% figureWidth = 1200; % Set desired width in pixels
% figureHeight = 800; % Set desired height in pixels
% figure('Position', [100, 100, figureWidth, figureHeight]); % Adjust the position and size

% Plot 1: Mean Prediction vs. Actual Binocular
subplot(2, 2, 1);
scatter(mean_prediction, binocular_data, 'filled');
hold on;
lsline; % Add least squares regression line
title('Mean Prediction');
xlabel('Mean of Left and Right (LogMAR)');
ylabel('Binocular (LogMAR)');
xlim([globalMin, globalMax]);
ylim([globalMin, globalMax]);
% Calculate and display correlation coefficient
r = corrcoef(mean_prediction, binocular_data);
text(globalMin + 0.05, globalMax - 0.05, sprintf('r = %.2f', r(1, 2)), 'FontSize', 12);
line([.2 2], [.2 2],'Color',[0 0 0])
axis equal 

% Plot 2: Min Prediction vs. Actual Binocular
subplot(2, 2, 2);
scatter(min_prediction, binocular_data, 'filled');
hold on;
lsline; % Add least squares regression line
title('Min Prediction');
xlabel('Min of Left and Right (LogMAR)');
ylabel('Binocular (LogMAR)');
xlim([globalMin, globalMax]);
ylim([globalMin, globalMax]);
% Calculate and display correlation coefficient
r = corrcoef(min_prediction, binocular_data);
text(globalMin + 0.05, globalMax - 0.05, sprintf('r = %.2f', r(1, 2)), 'FontSize', 12);
line([.2 2], [.2 2],'Color',[0 0 0])
axis equal 

% Plot 3: Left Eye vs. Actual Binocular
subplot(2, 2, 3);
scatter(left_eye_data, binocular_data, 'filled');
hold on;
lsline; % Add least squares regression line
title('Left vs. Bino');
xlabel('Left Eye (LogMAR)');
ylabel('Binocular (LogMAR)');
xlim([globalMin, globalMax]);
ylim([globalMin, globalMax]);
% Calculate and display correlation coefficient
r = corrcoef(left_eye_data, binocular_data);
text(globalMin + 0.05, globalMax - 0.05, sprintf('r = %.2f', r(1, 2)), 'FontSize', 12);
line([.2 2], [.2 2],'Color',[0 0 0])
axis equal 

% Plot 4: Right Eye vs. Actual Binocular
subplot(2, 2, 4);
scatter(right_eye_data, binocular_data, 'filled');
hold on;
lsline; % Add least squares regression line
title('Right vs. Bino');
xlabel('Right Eye (LogMAR)');
ylabel('Binocular (LogMAR)');
xlim([globalMin, globalMax]);
ylim([globalMin, globalMax]);
% Calculate and display correlation coefficient
r = corrcoef(right_eye_data, binocular_data);
text(globalMin + 0.05, globalMax - 0.05, sprintf('r = %.2f', r(1, 2)), 'FontSize', 12);
line([.2 2], [.2 2],'Color',[0 0 0])
axis equal 

% Save the figure
exportgraphics(gcf, '../figures/Macedonia_figures/binocular_prediction_scatterplots.pdf');


figure
hold on
scatter(right_eye_data, binocular_data, 'filled','r');
scatter(left_eye_data, binocular_data, 'filled','b');
line([right_eye_data; left_eye_data], [binocular_data; binocular_data],'Color',[0 0 0]) % needs to be pairwise
xlabel('Monocular (LogMAR)');
ylabel('Binocular (LogMAR)');
xlim([globalMin, globalMax]);
ylim([globalMin, globalMax]);
line([.2 2], [.2 2],'Color',[0 0 0])
    xline(log10(30/12.5), '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', fontSize);
    xline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1,'FontSize', fontSize);
        yline(log10(30/12.5), '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', fontSize);
    yline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1,'FontSize', fontSize);
axis equal 