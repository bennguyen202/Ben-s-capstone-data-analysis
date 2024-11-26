% Plot threshold of acuity at eccentricity experiment

clear all
close all

% Requires psychtoolbox
% Install from Matlab → Home → Add-ons → Get Add-ons → Search for Psychtoolbox → Add

% todo: test eccentricities [0, 1, 2, 4, 8] deg instead

% Define the file names
% todo: change json filename to sub-002_ecc-1.json etc
sub = '001';
data_dir = ['../data/sub-' sub '/'];
files = dir([data_dir 'sub-' sub '_ecc-*']);
file_names = {files.name};

%% Set figure defaults
fontSize = 14;
set(groot,'defaultAxesFontSize', fontSize)
set(groot,'defaultTextFontSize', fontSize)
set(groot,'defaultLegendFontSize', fontSize)
set(groot,'defaultAxesLineWidth',1)
set(groot,'defaultLineLineWidth',2)
set(groot,'defaultAxesTickDir', 'out');
set(groot,'defaultAxesTickDirMode', 'manual');

% Define colors for each plot
colors = lines(length(file_names)); % Use MATLAB's built-in colormap for distinct colors

% Create a figure with reduced width
% figure('Position', [100, 100, 1000, 500]);

%% Loop through each file and plot the data
for i = 1:length(file_names)
    % Load the JSON data
    data = jsondecode(fileread([data_dir file_names{i}]));

    % Extract data for both eyes and remove the last two entries for left/right eye
    both_eyes_data = data(1:end-2);

    % Extract eccentricity from the filename
    % todo: extract eccentricity from data instead - data.Eccentricity_d
    ecc_number = regexp(file_names{i}, 'ecc-(\d+)', 'tokens');
    ecc_number = str2double(ecc_number{1}{1});

    % Plot data for both eyes using LogMAR and add a red horizontal line with annotation
    trial_numbers_both = arrayfun(@(entry) entry.TrialNumber, both_eyes_data);
    logmar_values_both = arrayfun(@(entry) entry.LogMAR, both_eyes_data);
    ax = gca;
    plot_data_with_line(ax, trial_numbers_both, logmar_values_both, colors(i, :), i, ecc_number);
    hold on;
end

% The resolution of the Quest 2 is 20 pixels/degree
% so, 10 cycles/degree, or log10(30/cycpdeg) logMar
yline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1,'FontSize', fontSize) % Quest 2
yline(log10(30/12.5),'--','Meta Q3', 'LineWidth',1,'FontSize', fontSize) % Quest 3

% Adjust layout and display the figure
set(gcf, 'Color', 'w');
hold off;
exportgraphics(gcf, ['../figures/sub-' sub '_ecc-mixed.pdf']);

%% Todo: Plot and fit psychometric function
d = struct2table(data);
d.LogMAR = round(d.LogMAR,8); % regularize
% add isCorrect column
d.isCorrect = strcmp(d.CorrectOption, d.GuessedOption);
tblstats = grpstats(d,"LogMAR","mean","DataVars","isCorrect")
figure; hold on;
plot(tblstats.LogMAR, tblstats.mean_isCorrect)

xline(log10(30/10),'--', 'Meta Q2', 'LineWidth',1,'FontSize', fontSize) % Quest 2
xline(log10(30/12.5),'--','Meta Q3', 'LineWidth',1,'FontSize', fontSize) % Quest 3

xlabel('Letter size (logMAR)')
ylabel('Proportion correct')

% Compute sensitivity and bias
ff = 1;
[uEst(ff),varEst(ff)] = FitCumNormYN(d.LogMAR,strcmp(d.GuessedOption,d.CorrectOption),~strcmp(d.GuessedOption,d.CorrectOption)); % using Psychtoolbox

% plot fit
vas = 0:.01:1;
ys = cdf('norm',vas, uEst, sqrt(varEst));
plot(vas,ys)


%% Function to plot data and add a red horizontal line with annotation
function plot_data_with_line(ax, trial_numbers, logmar_values, color, index, ecc_number)
plot(ax, trial_numbers, logmar_values, 'o-', 'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', color, 'Color', color); % Smaller, colored circles
hold(ax, 'on');

num_final_values = 20;
avg_final_values = mean(logmar_values(end-num_final_values+1:end));

fontSize = 14;

% Plot the red dashed line at the average
yline(ax, avg_final_values, 'r--', 'Color', color);

% Add text annotation at the top right of the figure, offset by index
annotation('textbox', [0.85, 0.9 - 0.05 * index, 0.1, 0.1], 'String', sprintf('Threshold (%d deg): %.2f logMAR', ecc_number, avg_final_values), ...
    'EdgeColor', 'none', 'Color', color, 'FontSize', fontSize, 'HorizontalAlignment', 'right');

xlabel(ax, 'Trial Number');
ylabel(ax, 'Visual Acuity (LogMAR)');
title(ax, ['Both Eyes']);
% title(ax, ['Both Eyes | sub-' sub]);
ylim(ax, [0, 1]);  % Set fixed y-axis range
ax.Box = 'off';  % Remove top and right border
hold(ax, 'off');
end