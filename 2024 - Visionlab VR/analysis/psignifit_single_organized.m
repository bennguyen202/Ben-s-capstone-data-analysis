% Description: Analyzes and visualizes psychometric data for acuity/contrast experiments
% Requires psychtoolbox and psignifit

clear all
close all

%% Configuration

% for a single participant
plot_single_participant = false;
subject = '002';
session = '01';
experiment_type = 'contrast'; % Toggle: 'acuity' or 'contrast'
eccentricity = 7; % Only used for acuity

% for viewing psignifit results
create_threshold_table = true;

% toggles for combined plots
create_combined_psychometric = false; % combined plot for subjects listed below
batch_processing = true; % saves all 3 figures for all participants listed below
create_parameter_distributions = false; % histograms for slope and lapse rates

% for batch processing
subjects = {'002','007','010', '011','012','013','015', '016','017','018'};
%subjects = {'002', '004', '005'};
sessions = {'01', '02'};

% Load and process data
[data, d] = load_and_process_data(subject, session, experiment_type, eccentricity);
eye_conditions = unique({data.EyeCondition});

% Process all data
[trial_data, avg_thresholds] = process_trial_data(data, eye_conditions, experiment_type);
[psych_data, result] = process_psychometric_data(d, experiment_type);
[threshold_evolution] = process_threshold_evolution(d, eye_conditions, experiment_type);

% plot the 3 figures for a single participant
if plot_single_participant
set_figure_defaults();
plot_all_figures(trial_data, psych_data, threshold_evolution, avg_thresholds, ...
                subject, session, experiment_type, eccentricity, eye_conditions, result);
end
            
if create_threshold_table
    create_psignifit_threshold_table(subjects, sessions, experiment_type, eccentricity);
end
            
% batch process data
if batch_processing
    batch_process_subjects(experiment_type, subjects, sessions);
end

% Create combined plot if requested
if create_combined_psychometric
    plot_combined_psychometric_functions(experiment_type, subjects, sessions);
end

% Create parameter distributions
if create_parameter_distributions
    plot_parameter_distributions(experiment_type, subjects, sessions);
end

%% Data Loading and Processing Functions
function options = get_psignifit_options()
    options.sigmoidName = 'norm';
    options.expType = 'nAFC';
    options.expN = 10;
    options.fixedPars = nan(5,1);  % Don't fix any parameters
    % options.borders = [ ...
    %     nan, nan;   % threshold
    %     nan, nan;   % width
    %     0, 0.1;     % lower asymptote (guess rate, fixed at 0.1 for 10AFC)
    %     0, 0.2;     % upper asymptote (lapse rate, allow up to 0.2)
    %     nan, nan    % variance scaling
    % ];
end

function [data, d] = load_and_process_data(subject, session, experiment_type, eccentricity)
    % Base directory for figures
    figures_base_dir = '../figures/psignifit/';
    
    % Create subject directory if it doesn't exist
    subject_dir = fullfile(figures_base_dir, ['sub-' subject]);
    if ~exist(subject_dir, 'dir')
        mkdir(subject_dir);
    end
    
    % Define file paths
    base_dir = ['../data/sub-' subject '/'];
    if strcmp(experiment_type, 'acuity')
        data_dir = [base_dir 'acuity/'];
        file_name = sprintf('sub-%s_ecc-%d-%s.json', subject, eccentricity, session);
    else
        data_dir = [base_dir 'contrast/'];
        file_name = sprintf('sub-%s_cs-%s.json', subject, session);
    end
    
    % Load data
    data = jsondecode(fileread([data_dir file_name]));
    d = struct2table(data);
    d.isCorrect = strcmp(d.CorrectOption, d.GuessedOption);
end

function [trial_data, avg_thresholds] = process_trial_data(data, eye_conditions, experiment_type)
    trial_data = struct();
    avg_thresholds = struct();
    
    for j = 1:length(eye_conditions)
        eye_data = data(strcmp({data.EyeCondition}, eye_conditions{j}));
        trial_numbers = 1:length(eye_data);
        
        if strcmp(experiment_type, 'acuity')
            values = arrayfun(@(entry) entry.LogMAR, eye_data);
        else
            % Make contrast values negative
            values = -1 * abs(arrayfun(@(entry) entry.LogLum, eye_data));
        end
        
        trial_data.(eye_conditions{j}) = struct('trials', trial_numbers, 'values', values);
        
        % Calculate average threshold
        num_final_values = 20;
        if length(values) >= num_final_values
            avg_thresholds.(eye_conditions{j}) = mean(values(end-num_final_values+1:end));
        else
            avg_thresholds.(eye_conditions{j}) = mean(values);
        end
    end
end

function [psych_data, result] = process_psychometric_data(d, experiment_type)
    % Process data for each eye condition
    eye_conditions = unique(d.EyeCondition);
    psych_data = struct();
    result = struct();
    
    options = get_psignifit_options();
    
    for i = 1:length(eye_conditions)
        % Filter data for current eye condition
        eye_data = d(strcmp(d.EyeCondition, eye_conditions{i}), :);
        
        if strcmp(experiment_type, 'acuity')
            eye_data.LogMAR = round(eye_data.LogMAR, 8);
            tblstats = grpstats(eye_data, "LogMAR", "mean", "DataVars", "isCorrect");
            x_values = tblstats.LogMAR;
            tblstats_sum = grpstats(eye_data, "LogMAR", "sum", "DataVars", "isCorrect");
            data_for_fit = [tblstats_sum.LogMAR tblstats_sum.sum_isCorrect tblstats_sum.GroupCount];
            xlabel_text = 'Letter size (logMAR)';
        else
            % Make contrast values negative
            eye_data.LogLum = -1 * abs(eye_data.LogLum);
            tblstats = grpstats(eye_data, "LogLum", "mean", "DataVars", "isCorrect");
            x_values = tblstats.LogLum;
            tblstats_sum = grpstats(eye_data, "LogLum", "sum", "DataVars", "isCorrect");
            data_for_fit = [tblstats_sum.LogLum tblstats_sum.sum_isCorrect tblstats_sum.GroupCount];
            xlabel_text = 'Log Luminance';
        end
        
        % Compute psychometric fit
        %options.sigmoidName = 'norm';
        %options.expType = 'nAFC';
        %options.expN = 10;
        
        addpath(genpath('../psignifit'));
        result.(eye_conditions{i}) = psignifit(data_for_fit, options);
        
        % Store data for this condition
        psych_data.(eye_conditions{i}).x_values = x_values;
        psych_data.(eye_conditions{i}).y_values = tblstats.mean_isCorrect;
        psych_data.(eye_conditions{i}).data_for_fit = data_for_fit;
    end
    
    psych_data.xlabel = xlabel_text;
end

function [threshold_evolution] = process_threshold_evolution(d, eye_conditions, experiment_type)
    % Get actual number of trials available
    min_trials = inf;
    for i = 1:length(eye_conditions)
        eye_data = d(strcmp(d.EyeCondition, eye_conditions{i}), :);
        min_trials = min(min_trials, height(eye_data));
    end
    
    % Adjust trial steps based on available data
    max_trials = min(40, min_trials);  % Cap at 40 or available trials
    trial_steps = 5:1:max_trials;      % Start from 5 trials
    num_steps = length(trial_steps);
    num_conditions = length(eye_conditions);
    
    % Initialize storage
    thresholds = zeros(num_steps, num_conditions);
    ci_lower = zeros(num_steps, num_conditions);
    ci_upper = zeros(num_steps, num_conditions);
    
    options = get_psignifit_options();
    
    % Process each condition
    for i = 1:num_conditions
        % Get data for this eye condition
        eye_data = d(strcmp(d.EyeCondition, eye_conditions{i}), :);
        
        % Process each trial step
        for t = 1:num_steps
            n_trials = trial_steps(t);
            subset_data = eye_data(1:n_trials, :);
            
            % Calculate stats based on experiment type
            if strcmp(experiment_type, 'acuity')
                tbl_subset = grpstats(subset_data, "LogMAR", "sum", "DataVars", "isCorrect");
                data_subset = [tbl_subset.LogMAR tbl_subset.sum_isCorrect tbl_subset.GroupCount];
            else
                subset_data.LogLum = -1 * abs(subset_data.LogLum);
                tbl_subset = grpstats(subset_data, "LogLum", "sum", "DataVars", "isCorrect");
                data_subset = [tbl_subset.LogLum tbl_subset.sum_isCorrect tbl_subset.GroupCount];
            end
            
            % Fit psychometric function
            warning('off', 'all');
            result = psignifit(data_subset, options);
            warning('on', 'all');
            
            % Store results
            thresholds(t,i) = result.Fit(1);
            ci = result.conf_Intervals(1,:,3);
            ci_lower(t,i) = ci(1);
            ci_upper(t,i) = ci(2);
        end
    end
    
    % Store all evolution data
    threshold_evolution = struct();
    threshold_evolution.trial_steps = trial_steps;
    threshold_evolution.thresholds = thresholds;
    threshold_evolution.ci_lower = ci_lower;
    threshold_evolution.ci_upper = ci_upper;
end

%% Figure Setup and Plotting Functions
function set_figure_defaults()
    fontSize = 14;
    set(groot,'defaultAxesFontSize', fontSize)
    set(groot,'defaultTextFontSize', fontSize)
    set(groot,'defaultLegendFontSize', fontSize)
    set(groot,'defaultAxesLineWidth', 1)
    set(groot,'defaultLineLineWidth', 2)
    set(groot,'defaultAxesTickDir', 'out')
    set(groot,'defaultAxesTickDirMode', 'manual')
end

function plot_all_figures(trial_data, psych_data, threshold_evolution, avg_thresholds, ...
                         subject, session, experiment_type, eccentricity, eye_conditions, result)
    % Define colors
    colors = containers.Map();
    colors('Right') = [1 0 0];     % Red
    colors('Left') = [0 0 1];      % Blue
    colors('Both') = [0.5 0 0.5];  % Purple
    
    % Plot trial progression
    plot_trial_progression(trial_data, avg_thresholds, colors, subject, session, ...
                          experiment_type, eccentricity, eye_conditions);
    
    % Plot psychometric functions
    plot_psignifit_result(result, experiment_type);
    
    % Plot threshold evolution
    plot_threshold_evolution(threshold_evolution, colors, subject, session, ...
                           experiment_type, eye_conditions);
end

function plot_trial_progression(trial_data, avg_thresholds, colors, subject, session, ...
                              experiment_type, eccentricity, eye_conditions)
    figure;
    ax = gca;
    hold on;
    
    % Plot each condition
    for j = 1:length(eye_conditions)
        cond = eye_conditions{j};
        data = trial_data.(cond);
        plot_data_with_line(ax, data.trials, data.values, colors(cond), j, ...
                           eccentricity, cond, experiment_type, avg_thresholds.(cond));
    end
    
    % Set axis limits and labels
    if strcmp(experiment_type, 'acuity')
        ylim([0.3, 1.1]);
        yline(log10(30/10), '--', 'Meta Q2', 'LineWidth', 1, 'FontSize', 14);
        yline(log10(30/12.5), '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', 14);
    else
        ylim([-2, 0]);
    end
    xlim([1, length(data.trials)]);
    
    title(sprintf('%s - Sub %s - Test %s', capitalize(experiment_type), subject, session));
end

function plot_psignifit_result(result, experiment_type)
    figure('Position', [100, 100, 800, 600]);
    hold on;
    
    % Define colors
    colors = containers.Map();
    colors('Right') = [1 0 0];     % Red
    colors('Left') = [0 0 1];      % Blue
    colors('Both') = [0.5 0 0.5];  % Purple
    
    % Get all conditions
    conditions = fieldnames(result);
    
    % Plot each condition
    for i = 1:length(conditions)
        cond = conditions{i};
        color = colors(cond);
        
        % Plot the fitted curve with custom color
        plotOptions.lineColor = color;
        plotOptions.dataColor = color;
        plotOptions.lineWidth = 2;
        plotOptions.xLabel = '';
        plotOptions.yLabel = '';
        plotOptions.plotData = true;
        plotOptions.plotAsymptote = false;
        plotOptions.plotThreshold = false;
        
        plotPsych(result.(cond), plotOptions);
    end
    
    % Set axis limits and labels
    if strcmp(experiment_type, 'acuity')
        xlim([0.3, 1.1]);
        xline(log10(30/10), '--', 'Meta Q2', 'LineWidth', 1, 'FontSize', 14);
        xline(log10(30/12.5), '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', 14);
    else
        xlim([-2, 0]);
    end
    ylim([0, 1]);
    
    % Add labels and legend
    xlabel('Stimulus Intensity');
    ylabel('Proportion Correct');
    title('Psychometric Functions');
    legend(conditions, 'Location', 'best');
    grid on;
    box off;
    
    % Print thresholds
    fprintf('\nPsychometric Function Thresholds:\n');
    for i = 1:length(conditions)
        cond = conditions{i};
        threshold = result.(cond).Fit(1);
        ci = result.(cond).conf_Intervals(1,:,3);
        fprintf('%s: %.3f [%.3f, %.3f]\n', cond, threshold, ci(1), ci(2));
    end
end

function plot_threshold_evolution(threshold_evolution, colors, subject, session, ...
                                experiment_type, eye_conditions)
    figure;
    hold on;
    
    % Plot each condition
    for i = 1:length(eye_conditions)
        % Plot main threshold line
        plot(threshold_evolution.trial_steps, threshold_evolution.thresholds(:,i), '-', ...
             'Color', colors(eye_conditions{i}), 'LineWidth', 2, ...
             'DisplayName', eye_conditions{i});
        
        % Plot confidence intervals
        x2 = [threshold_evolution.trial_steps, fliplr(threshold_evolution.trial_steps)];
        inBetween = [threshold_evolution.ci_lower(:,i); flipud(threshold_evolution.ci_upper(:,i))]';
        fill(x2, inBetween, colors(eye_conditions{i}), 'FaceAlpha', 0.1, ...
             'EdgeColor', colors(eye_conditions{i}));
    end
    
    % Set axis limits and labels
    if strcmp(experiment_type, 'acuity')
        ylim([0.3, 1.1]);
        yline(log10(30/10), '--k', 'Meta Q2', 'LineWidth', 1, 'FontSize', 14);
        yline(log10(30/12.5), '--k', 'Meta Q3', 'LineWidth', 1, 'FontSize', 14);
        ylabel('Threshold (LogMAR)');
    else
        ylim([-2, 0]);
        ylabel('Threshold (Log Luminance)');
    end
    
    xlabel('Number of Trials');
    title(sprintf('Threshold Evolution - Sub %s - Test %s', subject, session));
    grid on;
    box off;
    
    % Create legend
    h = findobj(gcf, 'Type', 'line');
    legend([h(end:-3:1)], eye_conditions, 'Location', 'best');
    
    % Print final thresholds
    print_final_thresholds(threshold_evolution, eye_conditions);
end

function plot_parameter_distributions(experiment_type, subjects, sessions)
    % Initialize arrays to store parameters
    n_subjects = length(subjects);
    n_sessions = length(sessions);
    total_fits = n_subjects * n_sessions * 3; % 3 for Right, Left, Binocular
    
    slopes = zeros(total_fits, 1);
    lapse_rates = zeros(total_fits, 1);
    conditions = cell(total_fits, 1);
    subject_ids = cell(total_fits, 1);
    session_ids = cell(total_fits, 1);
    
    options = get_psignifit_options();
    
    % Setup psignifit options
    %options.sigmoidName = 'norm';
    %options.expType = 'nAFC';
    %options.expN = 10;
    
    fprintf('Processing parameter distributions...\n');
    
    % Collect parameters from all fits
    idx = 1;
    for s = 1:n_subjects
        subject = subjects{s};
        for sess = 1:n_sessions
            session = sessions{sess};
            
            try
                % Load and process data
                [data, d] = load_and_process_data(subject, session, experiment_type, 5);
                eye_conditions = unique({data.EyeCondition});
                
                % Process each eye condition
                for eye_cond = eye_conditions
                    % Get data for psychometric fit
                    eye_data = d(strcmp(d.EyeCondition, eye_cond), :);
                    
                    if strcmp(experiment_type, 'acuity')
                        eye_data.LogMAR = round(eye_data.LogMAR, 8);
                        tbl_sum = grpstats(eye_data, "LogMAR", "sum", "DataVars", "isCorrect");
                        data_for_fit = [tbl_sum.LogMAR tbl_sum.sum_isCorrect tbl_sum.GroupCount];
                    else
                        eye_data.LogLum = -1 * abs(eye_data.LogLum);
                        tbl_sum = grpstats(eye_data, "LogLum", "sum", "DataVars", "isCorrect");
                        data_for_fit = [tbl_sum.LogLum tbl_sum.sum_isCorrect tbl_sum.GroupCount];
                    end
                    
                    % Fit psychometric function
                    result = psignifit(data_for_fit, options);
                    
                    % Store parameters
                    slopes(idx) = log10(result.Fit(2));  % Width parameter
                    lapse_rates(idx) = result.Fit(3);  % Upper asymptote
                    conditions{idx} = eye_cond{1};
                    subject_ids{idx} = subject;
                    session_ids{idx} = session;
                    
                    idx = idx + 1;
                end
            catch ME
                warning('Error processing subject %s session %s: %s', subject, session, ME.message);
                continue;
            end
        end
    end
    
    % Print summary statistics before plotting
    fprintf('\nLapse Rate Summary:\n');
    fprintf('Mean: %.4f\n', mean(lapse_rates));
    fprintf('Std: %.4f\n', std(lapse_rates));
    fprintf('Min: %.4f\n', min(lapse_rates));
    fprintf('Max: %.4f\n', max(lapse_rates));
    
    % Create figure for parameter distributions
    figure('Position', [100 100 1200 600]);
    
    % Plot slope distribution
    subplot(1,2,1);
    histogram(slopes, 20, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'k');
    hold on;
    xline(mean(slopes), 'r--', 'LineWidth', 2);
    xline(mean(slopes) + 2*std(slopes), 'r:', 'LineWidth', 1.5);
    xline(mean(slopes) - 2*std(slopes), 'r:', 'LineWidth', 1.5);
    title('Distribution of Log10(Slope) Parameters');
    xlabel('Slope');
    ylabel('Frequency');
    grid on;
    
    % Plot lapse rate distribution
    subplot(1,2,2);
    histogram(lapse_rates, 20, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'k');
    hold on;
    xline(mean(lapse_rates), 'r--', 'LineWidth', 2);
    xline(mean(lapse_rates) + 2*std(lapse_rates), 'r:', 'LineWidth', 1.5);
    xline(mean(lapse_rates) - 2*std(lapse_rates), 'r:', 'LineWidth', 1.5);
    title('Distribution of Lapse Rates');
    xlabel('Lapse Rate');
    ylabel('Frequency');
    grid on;
    
    % Print summary statistics and potential outliers
    fprintf('\nParameter Distribution Summary:\n');
    fprintf('Slopes: Mean = %.3f, SD = %.3f\n', mean(slopes), std(slopes));
    fprintf('Lapse Rates: Mean = %.3f, SD = %.3f\n', mean(lapse_rates), std(lapse_rates));
    
    % Identify potential outliers (beyond 2 SD)
    fprintf('\nPotential Outliers (beyond 2 SD):\n');
    slope_threshold = mean(slopes) + 2*std(slopes);
    lapse_threshold = mean(lapse_rates) + 2*std(lapse_rates);
    
    fprintf('\nSlope Outliers:\n');
    outlier_idx = abs(slopes - mean(slopes)) > 2*std(slopes);
    for i = find(outlier_idx)'
        fprintf('Subject %s, Session %s, %s: Slope = %.3f\n', ...
            subject_ids{i}, session_ids{i}, conditions{i}, slopes(i));
    end
    
    fprintf('\nLapse Rate Outliers:\n');
    outlier_idx = abs(lapse_rates - mean(lapse_rates)) > 2*std(lapse_rates);
    for i = find(outlier_idx)'
        fprintf('Subject %s, Session %s, %s: Lapse Rate = %.3f\n', ...
            subject_ids{i}, session_ids{i}, conditions{i}, lapse_rates(i));
    end
end

%% Helper Functions
function plot_data_with_line(ax, trial_numbers, values, color, index, ecc_number, ...
                            eye_condition, experiment_type, avg_value)
    % Plot data points and line
    plot(ax, trial_numbers, values, 'o-', 'LineWidth', 1.5, 'MarkerSize', 4, ...
         'MarkerFaceColor', color, 'Color', color);

    fontSize = 14;

    % Plot the average line
    yline(ax, avg_value, 'r--', 'Color', color);

    % Add text annotation
    if strcmp(experiment_type, 'acuity')
        annotation('textbox', [0.8, 0.85 - 0.05 * index, 0.1, 0.1], ...
            'String', sprintf('Threshold (%s, %d deg): %.2f logMAR', ...
            eye_condition, ecc_number, avg_value), ...
            'EdgeColor', 'none', 'Color', color, 'FontSize', fontSize, ...
            'HorizontalAlignment', 'right');
        ylabel(ax, 'Visual Acuity (LogMAR)');
    else
        annotation('textbox', [0.8, 0.85 - 0.05 * index, 0.1, 0.1], ...
            'String', sprintf('Threshold (%s): %.2f LogLum', ...
            eye_condition, avg_value), ...
            'EdgeColor', 'none', 'Color', color, 'FontSize', fontSize, ...
            'HorizontalAlignment', 'right');
        ylabel(ax, 'Log Luminance');
    end

    xlabel(ax, 'Trial Number');
    ax.Box = 'off';
end

function print_final_thresholds(threshold_evolution, eye_conditions)
    fprintf('\nFinal Thresholds (40 trials per condition):\n');
    for i = 1:length(eye_conditions)
        fprintf('%s eye: %.3f [%.3f, %.3f]\n', ...
            eye_conditions{i}, ...
            threshold_evolution.thresholds(end,i), ...
            threshold_evolution.ci_lower(end,i), ...
            threshold_evolution.ci_upper(end,i));
    end
end

function str = capitalize(str)
    str = regexprep(str, '(^.)', '${upper($1)}');
end

function batch_process_subjects(exp, subs, sess)
    % Configuration
    subjects = subs;
    sessions = sess;  % All possible sessions
    experiment_type = exp; % Toggle: 'acuity' or 'contrast'
    eccentricity = 7; % Only used for acuity
    
    options = get_psignifit_options();

    % Loop through each subject
    for subject = subjects
        subject = subject{1}; % Extract string from cell
        
        % Create subject directory if it doesn't exist
        subject_dir = fullfile('../figures/psignifit', ['sub-' subject], experiment_type);
        if ~exist(subject_dir, 'dir')
            mkdir(subject_dir);
        end
        
        % Loop through each session
        for session = sessions
            session = session{1}; % Extract string from cell
            
            % Check if data file exists
            if strcmp(experiment_type, 'acuity')
                data_file = sprintf('../data/sub-%s/acuity/sub-%s_ecc-%d-%s.json', ...
                    subject, subject, eccentricity, session);
            else
                data_file = sprintf('../data/sub-%s/contrast/sub-%s_cs-%s.json', ...
                    subject, subject, session);
            end
            
            % Process only if file exists
            if exist(data_file, 'file')
                try
                    % Load and process data
                    [data, d] = load_and_process_data(subject, session, experiment_type, eccentricity);
                    eye_conditions = unique({data.EyeCondition});
                    
                    % Process all data
                    [trial_data, avg_thresholds] = process_trial_data(data, eye_conditions, experiment_type);
                    [psych_data, result] = process_psychometric_data(d, experiment_type);
                    [threshold_evolution] = process_threshold_evolution(d, eye_conditions, experiment_type);
                    
                    % Set figure defaults
                    set_figure_defaults();
                    
                    % Create and save figures
                    % 1. Staircase
                    figure('Position', [100, 100, 800, 600]);
                    plot_trial_progression(trial_data, avg_thresholds, get_colors(), subject, session, ...
                        experiment_type, eccentricity, eye_conditions);
                    saveas(gcf, fullfile(subject_dir, ...
                        sprintf('sub-%s_ses-%s_staircase.pdf', subject, session)));
                    close;
                    
                    % 2. Psychometric curve
                    figure('Position', [100, 100, 800, 600]);
                    plot_psignifit_result(result, experiment_type);
                    saveas(gcf, fullfile(subject_dir, ...
                        sprintf('sub-%s_ses-%s_psychometric.pdf', subject, session)));
                    close;
                    
                    % 3. Threshold evolution
                    figure('Position', [100, 100, 800, 600]);
                    plot_threshold_evolution(threshold_evolution, get_colors(), subject, session, ...
                        experiment_type, eye_conditions);
                    saveas(gcf, fullfile(subject_dir, ...
                        sprintf('sub-%s_ses-%s_evolution.pdf', subject, session)));
                    close;
                    
                    fprintf('Processed subject %s session %s successfully\n', subject, session);
                    
                catch ME
                    fprintf('Error processing subject %s session %s: %s\n', ...
                        subject, session, ME.message);
                    continue;
                end
            end
        end
    end
end

function plot_combined_psychometric_functions(experiment_type, subs, sess)
    % Configuration
    subjects = subs;
    sessions = sess;
    eccentricity = 7; % Only used for acuity
    
    options = get_psignifit_options();
    
    % Setup psignifit options
    %options.sigmoidName = 'norm';
    %options.expType = 'nAFC';
    %options.expN = 10;
    
    % Create figure
    figure('Position', [100, 100, 1200, 800]);
    hold on;
    
    % Colors for different conditions
    colors = struct('Right', [1 0 0], 'Left', [0 0 1], 'Both', [0.5 0 0.5]);
    
    % Process each subject
    for subj_idx = 1:length(subjects)
        subject = subjects{subj_idx};
        
        % Combine data from both sessions
        combined_data = struct();
        
        % Process each session
        for sess_idx = 1:length(sessions)
            session = sessions{sess_idx};
            
            % Load data
            try
                [data, d] = load_and_process_data(subject, session, experiment_type, eccentricity);
                
                % Process each eye condition
                eye_conditions = unique({data.EyeCondition});
                for eye_cond = eye_conditions
                    eye_data = d(strcmp(d.EyeCondition, eye_cond{1}), :);
                    
                    if strcmp(experiment_type, 'acuity')
                        eye_data.LogMAR = round(eye_data.LogMAR, 8);
                        tbl_sum = grpstats(eye_data, "LogMAR", "sum", "DataVars", "isCorrect");
                        data_for_fit = [tbl_sum.LogMAR tbl_sum.sum_isCorrect tbl_sum.GroupCount];
                    else
                        % Make contrast values negative
                        eye_data.LogLum = -1 * abs(eye_data.LogLum);
                        tbl_sum = grpstats(eye_data, "LogLum", "sum", "DataVars", "isCorrect");
                        data_for_fit = [tbl_sum.LogLum tbl_sum.sum_isCorrect tbl_sum.GroupCount];
                    end
                    
                    % Combine with existing data or create new
                    if isfield(combined_data, eye_cond{1})
                        combined_data.(eye_cond{1}) = [combined_data.(eye_cond{1}); data_for_fit];
                    else
                        combined_data.(eye_cond{1}) = data_for_fit;
                    end
                end
            catch ME
                warning('Error processing subject %s session %s: %s', subject, session, ME.message);
                continue;
            end
        end
        
        % Fit and plot combined data for each eye condition
        eye_conditions = fieldnames(combined_data);
        for eye_idx = 1:length(eye_conditions)
            eye_cond = eye_conditions{eye_idx};
            data_to_fit = combined_data.(eye_cond);
            
            % Fit psychometric function
            result = psignifit(data_to_fit, options);
            
            % Plot with reduced opacity
            plotOptions.lineColor = colors.(eye_cond);
            plotOptions.dataColor = colors.(eye_cond);
            plotOptions.lineWidth = 1;
            plotOptions.xLabel = '';
            plotOptions.yLabel = '';
            plotOptions.plotData = true;
            plotOptions.dataSize = 5;
            plotOptions.dataAlpha = 0.3;
            plotOptions.lineAlpha = 0.3;
            plotOptions.plotAsymptote = false;
            plotOptions.plotThreshold = false;
            
            plotPsych(result, plotOptions);
        end
    end
    
    % Set axis limits and labels
    if strcmp(experiment_type, 'acuity')
        xlim([0.3, 1.1]);
        xlabel('Visual Acuity (LogMAR)');
        % Add Meta Quest reference lines
        xline(log10(30/10), '--', 'Meta Q2', 'LineWidth', 1, 'FontSize', 14);
        xline(log10(30/12.5), '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', 14);
    else
        xlim([-2.25, -1]);
        xlabel('Log Luminance');
    end
    ylim([0, 1]);
    ylabel('Proportion Correct');
    
    % Add title and legend
    title(sprintf('Combined Psychometric Functions - All Subjects (%s)', ...
          capitalize(experiment_type)), 'FontSize', 16);
    legend({'Right Eye', 'Left Eye', 'Binocular'}, 'Location', 'best');
    
    % Formatting
    grid on;
    box off;
    set(gca, 'FontSize', 14);
end

% Add this function at the end with your other helper functions:
function create_psignifit_threshold_table(subjects, sessions, experiment_type, eccentricity)
    fprintf('\nThreshold Summary Table:\n');
    fprintf('----------------------------------------\n');
    fprintf('Subject\tSession\tRight\tLeft\tBoth\n');
    fprintf('----------------------------------------\n');

    % Initialize arrays for table data
    subject_list = [];
    session_list = [];
    right_thresholds = [];
    left_thresholds = [];
    both_thresholds = [];

    % Process each subject
    for subj_idx = 1:length(subjects)
        subject = subjects{subj_idx};
        
        % Process each session
        for sess_idx = 1:length(sessions)
            session = sessions{sess_idx};
            
            try
                % Load and process data
                [data, d] = load_and_process_data(subject, session, experiment_type, eccentricity);
                eye_conditions = unique({data.EyeCondition});
                
                % Initialize thresholds for this subject/session
                right_thresh = NaN;
                left_thresh = NaN;
                both_thresh = NaN;
                
                % Process each eye condition
                for eye_cond = eye_conditions
                    eye_data = d(strcmp(d.EyeCondition, eye_cond{1}), :);
                    
                    if strcmp(experiment_type, 'acuity')
                        eye_data.LogMAR = round(eye_data.LogMAR, 8);
                        tbl_sum = grpstats(eye_data, "LogMAR", "sum", "DataVars", "isCorrect");
                        data_for_fit = [tbl_sum.LogMAR tbl_sum.sum_isCorrect tbl_sum.GroupCount];
                    else
                        eye_data.LogLum = -1 * abs(eye_data.LogLum);
                        tbl_sum = grpstats(eye_data, "LogLum", "sum", "DataVars", "isCorrect");
                        data_for_fit = [tbl_sum.LogLum tbl_sum.sum_isCorrect tbl_sum.GroupCount];
                    end
                    
                    % Fit psychometric function
                    options = get_psignifit_options();
                    result = psignifit(data_for_fit, options);
                    
                    % Store threshold based on eye condition
                    switch eye_cond{1}
                        case 'Right'
                            right_thresh = result.Fit(1);
                        case 'Left'
                            left_thresh = result.Fit(1);
                        case 'Both'
                            both_thresh = result.Fit(1);
                    end
                end
                
                % Store data for table
                subject_list = [subject_list; string(subject)];
                session_list = [session_list; string(session)];
                right_thresholds = [right_thresholds; right_thresh];
                left_thresholds = [left_thresholds; left_thresh];
                both_thresholds = [both_thresholds; both_thresh];
                
                % Print row
                fprintf('%s\t%s\t%.3f\t%.3f\t%.3f\n', ...
                    subject, session, right_thresh, left_thresh, both_thresh);
                
            catch ME
                warning('Error processing subject %s session %s: %s', subject, session, ME.message);
                % Add row with NaN values
                subject_list = [subject_list; string(subject)];
                session_list = [session_list; string(session)];
                right_thresholds = [right_thresholds; NaN];
                left_thresholds = [left_thresholds; NaN];
                both_thresholds = [both_thresholds; NaN];
                fprintf('%s\t%s\tError\tError\tError\n', subject, session);
            end
        end
    end

    % Create and display summary statistics
    fprintf('----------------------------------------\n');
    fprintf('Summary Statistics:\n');
    fprintf('----------------------------------------\n');
    fprintf('Right Eye: Mean = %.3f, SD = %.3f\n', ...
        mean(right_thresholds, 'omitnan'), std(right_thresholds, 'omitnan'));
    fprintf('Left Eye:  Mean = %.3f, SD = %.3f\n', ...
        mean(left_thresholds, 'omitnan'), std(left_thresholds, 'omitnan'));
    fprintf('Both Eyes: Mean = %.3f, SD = %.3f\n', ...
        mean(both_thresholds, 'omitnan'), std(both_thresholds, 'omitnan'));

    % Round the threshold values to 2 decimal places
    right_thresholds = round(right_thresholds, 2);
    left_thresholds = round(left_thresholds, 2);
    both_thresholds = round(both_thresholds, 2);

    % Create MATLAB table for potential export
    threshold_table = table(subject_list, session_list, ...
        right_thresholds, left_thresholds, both_thresholds, ...
        'VariableNames', {'Subject', 'Session', 'Right', 'Left', 'Both'});

    % Save to CSV
    output_file = fullfile('../data/spreadsheet', sprintf('thresholds_%s.csv', experiment_type));
    writetable(threshold_table, output_file);
    fprintf('\nThreshold table saved to %s\n', output_file);
end

function colors = get_colors()
    colors = containers.Map();
    colors('Right') = [1 0 0];     % Red
    colors('Left') = [0 0 1];      % Blue
    colors('Both') = [0.5 0 0.5];  % Purple
end