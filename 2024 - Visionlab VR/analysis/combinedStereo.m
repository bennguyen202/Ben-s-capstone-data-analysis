clear all
close all

% Configuration
%subjects = {'002','004', '005', '006', '007', '008', '009', '010', '011','013','014','015'};
subjects = {'002','004', '005', '006','014','015'};
experiment_type = 'contrast'; % Change to 'contrast' for contrast sensitivity
eccentricity = 5; % Only used for acuity
test_numbers = {'03', '04'}; % Test and retest

% Set figure defaults
fontSize = 25;
set(groot,'defaultAxesFontSize', fontSize)
set(groot,'defaultTextFontSize', fontSize)
set(groot,'defaultLegendFontSize', fontSize)
set(groot,'defaultAxesLineWidth',1)
set(groot,'defaultLineLineWidth',2)
set(groot,'defaultAxesTickDir', 'out');
set(groot,'defaultAxesTickDirMode', 'manual');

% Create figure with 3 subplots
figure('Position', [100 100 1200 800]);

% Define colors for each eye condition
right_color = 'r';
left_color = 'b';
bino_color = [0.5 0 0.5]; % purple

% Create subplots for each eye condition
subplot_titles = {'Left Eye', 'Binocular', 'Right Eye'};
eye_conditions = {'Left', 'Both', 'Right'};
colors = {left_color, bino_color, right_color};

% Initialize arrays to store thresholds for each eye condition
thresholds = zeros(length(subjects), 3);

% Loop through each eye condition (subplot)
for eye_idx = 1:3
    subplot(1, 3, eye_idx);
    hold on;
    
    % Loop through each subject
    for sub_idx = 1:length(subjects)
        sub = subjects{sub_idx};
        
        % Loop through test and retest
        for test_idx = 1:length(test_numbers)
            test_number = test_numbers{test_idx};
            
            % Define the file path
            base_dir = ['../data/sub-' sub '/'];
            if strcmp(experiment_type, 'acuity')
                data_dir = [base_dir 'acuity/'];
                file_name = sprintf('sub-%s_ecc-%d-%s.json', sub, eccentricity, test_number);
            else
                data_dir = [base_dir 'contrast/'];
                file_name = sprintf('sub-%s_cs-%s.json', sub, test_number);
            end
            
            % Load and process data if file exists
            try
                data = jsondecode(fileread([data_dir file_name]));
                
                % Filter data for current eye condition
                eye_data = data(strcmp({data.EyeCondition}, eye_conditions{eye_idx}));
                
                if ~isempty(eye_data)
                    % Extract values and make them absolute
                    trial_numbers = 1:length(eye_data);
                    if strcmp(experiment_type, 'acuity')
                        values = arrayfun(@(entry) entry.LogMAR, eye_data);
                    else
                        values = -1 * abs(arrayfun(@(entry) abs(entry.LogLum), eye_data));  
                    end

                    % Plot with slight transparency
                    plot(trial_numbers, values, 'Color', [colors{eye_idx}, 0.3], 'LineWidth', 1);

                    % Calculate threshold for the last 20 trials
                    if length(values) >= 20
                        thresholds(sub_idx, eye_idx) = mean(values(end-19:end));
                    end
                end
            catch
                warning('Could not load file: %s', [data_dir file_name]);
            end
        end
    end
    
    % Calculate and display the overall average threshold for this eye condition
    overall_avg_threshold = mean(thresholds(:, eye_idx), 'omitnan');
    text(0.5, 0.9, sprintf('Avg Threshold: %.2f', overall_avg_threshold), ...
        'Units', 'normalized', 'FontSize', fontSize, 'HorizontalAlignment', 'center');
    
    % Customize subplot
    title(subplot_titles{eye_idx});
    xlabel('Trial Number');
    if strcmp(experiment_type, 'acuity')
        ylabel('Visual Acuity (LogMAR)');
        ylim([0.3, 1.1]);
        yline(log10(30/10),'--k', 'Meta Q2', 'LineWidth',1,'FontSize', fontSize);
        yline(log10(30/12.5),'--k','Meta Q3', 'LineWidth',1,'FontSize', fontSize);
    else
        ylabel('Log Luminance');
        ylim([-2.4, -0.8]); 
    end
    grid on;
    box off;
end

% Add overall title
if strcmp(experiment_type, 'acuity')
    sgtitle('Visual Acuity Staircases - All Subjects', 'FontSize', fontSize+2);
else
    sgtitle('Contrast Sensitivity Staircases - All Subjects', 'FontSize', fontSize+2);
end

% Save the figure
saveas(gcf, sprintf('../figures/all_subjects_%s_staircases.pdf', experiment_type));