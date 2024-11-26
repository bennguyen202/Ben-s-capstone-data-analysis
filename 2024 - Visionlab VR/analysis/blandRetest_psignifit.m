% Select visualization type: 'acuity' or 'contrast'
visualization_type = 'contrast';  % Toggle between 'acuity' and 'contrast'

% Select method: 'vr' or 'chart'
method_type = 'vr';  % Toggle between 'vr' and 'chart'

% Get first 12 participants
%subjects = {'002', '004', '005', '006', '007', '008', '009', '010', '011', '013', '014', '015'};
subjects = {'004', '005', '006', '014', '015'};
n_participants = length(subjects);

sessions = {'03', '04'};

% Initialize arrays to store thresholds
s1_R = zeros(n_participants, 1);
s1_L = zeros(n_participants, 1);
s1_B = zeros(n_participants, 1);
s2_R = zeros(n_participants, 1);
s2_L = zeros(n_participants, 1);
s2_B = zeros(n_participants, 1);

    
% Process each subject
for i = 1:n_participants
    subject = subjects{i};
    
    % Add diagnostic printing
    fprintf('\nProcessing subject: %s\n', subject);
    
    % Process both sessions
    for session = sessions
        sess = session{1};
        
        % Construct file path based on test type
        if strcmp(visualization_type, 'acuity')
            data_file = sprintf('../data/sub-%s/acuity/sub-%s_ecc-5-%s.json', ...
                subject, subject, sess);
        else
            data_file = sprintf('../data/sub-%s/contrast/sub-%s_cs-%s.json', ...
                subject, subject, sess);
        end
        
        % Load and process data if file exists
        if exist(data_file, 'file')
            % Load data
            data = jsondecode(fileread(data_file));
            d = struct2table(data);
            
            d.isCorrect = strcmp(d.CorrectOption, d.GuessedOption);
            
            % Process each eye condition
            for eye_cond = {'Right', 'Left', 'Both'}
                cond = eye_cond{1};
                eye_data = d(strcmp(d.EyeCondition, cond), :);
                
                % Prepare data for psignifit
                if strcmp(visualization_type, 'acuity')
                    eye_data.LogMAR = round(eye_data.LogMAR, 8);
                    tblstats = grpstats(eye_data, "LogMAR", "sum", "DataVars", "isCorrect");
                    data_for_fit = [tblstats.LogMAR tblstats.sum_isCorrect tblstats.GroupCount];
                else
                    % Make contrast values negative
                    eye_data.LogLum = -1 * abs(eye_data.LogLum);
                    tblstats = grpstats(eye_data, "LogLum", "sum", "DataVars", "isCorrect");
                    data_for_fit = [tblstats.LogLum tblstats.sum_isCorrect tblstats.GroupCount];
                end
                
                % Fit psychometric function
                options.sigmoidName = 'norm';
                options.expType = 'nAFC';
                options.expN = 10;
                
                warning('off', 'all');
                result = psignifit(data_for_fit, options);
                warning('on', 'all');
                
                % Store threshold based on session and condition
                threshold = result.Fit(1);
                if strcmp(sess, sessions{1})
                    if strcmp(cond, 'Right')
                        s1_R(i) = threshold;
                    elseif strcmp(cond, 'Left')
                        s1_L(i) = threshold;
                    else
                        s1_B(i) = threshold;
                    end
                else
                    if strcmp(cond, 'Right')
                        s2_R(i) = threshold;
                    elseif strcmp(cond, 'Left')
                        s2_L(i) = threshold;
                    else
                        s2_B(i) = threshold;
                    end
                end
            end
        else
            fprintf('File not found: %s\n', data_file);
        end
    end
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
    % Fixed x-axis limits for acuity
    x_min = -2.25;
    x_max = -0.9;
end

y_min = floor(min(all_diffs)*10)/10 - 0.2;  % Added extra space below
y_max = ceil(max(all_diffs)*10)/10 + 0.2;   % Added extra space above

% Create single figure
figure('Position', [100 100 800 600]);

% Colors for each condition
right_color = 'r';
left_color = 'b';
bino_color = [0.5 0 0.5]; % purple

% Set labels based on visualization type
if strcmp(visualization_type, 'acuity')
    x_label = sprintf('Mean of Sessions %s & %s (logMAR)', sessions{1}, sessions{2});
    y_label = sprintf('Difference (Session %s - Session %s)', sessions{1}, sessions{2});
    plot_title = sprintf('Bland-Altman Plot: %s Visual Acuity Test-Retest (Sessions %s vs %s)', ...
        method_type, sessions{1}, sessions{2});
else
    x_label = sprintf('Mean of Sessions %s & %s (log units)', sessions{1}, sessions{2});
    y_label = sprintf('Difference (Session %s - Session %s)', sessions{1}, sessions{2});
    plot_title = sprintf('Bland-Altman Plot: %s Contrast Sensitivity Test-Retest (Sessions %s vs %s)', ...
        method_type, sessions{1}, sessions{2});
end

% Add Meta Quest reference lines for acuity
if strcmp(visualization_type, 'acuity')
    fontSize = 16;
    metaQ2 = log10(30/10);
    metaQ3 = log10(30/12.5);
    
    % Vertical and horizontal lines
    xline(metaQ2, '--', 'Meta Q2', 'LineWidth', 1, 'FontSize', fontSize, 'Color', [0.5 0.5 0.5]);
    xline(metaQ3, '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', fontSize, 'Color', [0.5 0.5 0.5]);
end

% Create Bland-Altman plot
createBlandAltmanPlot(s1_R, s2_R, 'Right Eye', right_color, ...
                      s1_L, s2_L, 'Left Eye', left_color, ...
                      s1_B, s2_B, 'Binocular', bino_color, ...
                      x_label, y_label, x_min, x_max, y_min, y_max, plot_title, ...
                      visualization_type, method_type);
                  
                  
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
    hold on;
    
    if strcmp(visualization_type, 'contrast') && strcmp(method_type, 'chart')
        % Add jitter for chart contrast condition
        jitter = 0.01;
        jitter_R = (rand(size(means_R)) - 0.5) * jitter;
        jitter_L = (rand(size(means_L)) - 0.5) * jitter;
        jitter_B = (rand(size(means_B)) - 0.5) * jitter;
        
        % Plot connecting lines first
        for i = 1:length(means_L)
            plot([means_L(i)+jitter_L(i), means_B(i)+jitter_B(i)], ...
                 [differences_L(i)+jitter_L(i), differences_B(i)+jitter_B(i)], ...
                 '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
            plot([means_B(i)+jitter_B(i), means_R(i)+jitter_R(i)], ...
                 [differences_B(i)+jitter_B(i), differences_R(i)+jitter_R(i)], ...
                 '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
        end
        
        % Plot points
        scatter(means_R + jitter_R, differences_R + jitter_R, 100, colorR, 'filled', ...
                'MarkerFaceAlpha', 0.7, 'DisplayName', titleR);
        scatter(means_L + jitter_L, differences_L + jitter_L, 100, colorL, 'filled', ...
                'MarkerFaceAlpha', 0.7, 'DisplayName', titleL);
        scatter(means_B + jitter_B, differences_B + jitter_B, 100, colorB, 'filled', ...
                'MarkerFaceAlpha', 0.7, 'DisplayName', titleB);
    else
        % Regular plotting for all other conditions
        % Plot connecting lines first
        for i = 1:length(means_L)
            plot([means_L(i), means_B(i)], [differences_L(i), differences_B(i)], ...
                 '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
            plot([means_B(i), means_R(i)], [differences_B(i), differences_R(i)], ...
                 '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
        end
        
        % Plot points
        scatter(means_R, differences_R, 100, colorR, 'filled', ...
                'MarkerFaceAlpha', 0.7, 'DisplayName', titleR);
        scatter(means_L, differences_L, 100, colorL, 'filled', ...
                'MarkerFaceAlpha', 0.7, 'DisplayName', titleL);
        scatter(means_B, differences_B, 100, colorB, 'filled', ...
                'MarkerFaceAlpha', 0.7, 'DisplayName', titleB);
    end
    
    % Add reference lines with increased font size and line width
    yline(meanDiff, 'k-', sprintf('Mean = %.2f', meanDiff), 'LineWidth', 2, 'FontSize', 20);
    yline(upperLimit, 'k--', sprintf('+1.96 SD = %.2f', upperLimit), 'LineWidth', 2, 'FontSize', 20);
    yline(lowerLimit, 'k--', sprintf('-1.96 SD = %.2f', lowerLimit), 'LineWidth', 2, 'FontSize', 20);
    yline(0, 'k:', 'LineWidth', 2); % Zero line
    
    % Add Meta Quest reference lines for acuity
    if strcmp(visualization_type, 'acuity')
        fontSize = 20;  % Match the font size of other labels
        %yline(log10(30/10), '--', 'Meta Q2', 'LineWidth', 1, 'FontSize', fontSize, 'Color', [0.5 0.5 0.5]);
        %yline(log10(30/12.5), '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', fontSize, 'Color', [0.5 0.5 0.5]);
    end
    
    % Set axes limits
    xlim([x_min x_max]);
    ylim([y_min y_max]);
    
    % Labels and title
    xlabel(x_label);
    ylabel(y_label);
    title(plot_title, 'FontSize', 20);
    grid on;
    legend('Location', 'southeast');
    
    % Only create secondary x-axis for contrast chart condition
    if strcmp(visualization_type, 'contrast') && strcmp(method_type, 'chart')
        % Create secondary x-axis for percent contrast
        ax2 = axes('Position', get(ax1, 'Position'), ...
                   'XAxisLocation', 'top', ...
                   'Color', 'none', ...
                   'XColor', 'k');

        % Link the axes
        linkaxes([ax1 ax2], 'x');

        % Set the x limits for both axes
        xlim(ax2, [x_min x_max]);

        % Calculate tick positions for percent contrast
        log_ticks = x_min:0.2:x_max;
        percent_ticks = 100 * (10 .^ (-log_ticks));

        % Set the ticks and labels for the secondary axis
        set(ax2, 'XTick', log_ticks);
        set(ax2, 'XTickLabel', arrayfun(@(x) sprintf('%.1f%%', x), percent_ticks, 'UniformOutput', false));
        xlabel(ax2, 'Contrast (%)');

        % Make sure the secondary axis stays on top
        uistack(ax2, 'top');

        % Hide secondary y-axis
        set(ax2, 'YTick', []);
        
        % Move title above secondary axis
        ax1.Title.Position(2) = ax1.Title.Position(2) - 0.05;
    end
    
    % Print statistics
    fprintf('\nOverall Statistics:\n');
    fprintf('Mean difference: %.3f\n', meanDiff);
    fprintf('Standard deviation of differences: %.3f\n', sdDiff);
    fprintf('95%% Limits of agreement: (%.3f to %.3f)\n', lowerLimit, upperLimit);
    
    % Print condition-specific statistics
    fprintf('\nCondition-Specific Statistics:\n');
    
    % Right eye
    fprintf('\nRight Eye:\n');
    fprintf('Mean difference: %.3f\n', mean(differences_R));
    fprintf('SD of differences: %.3f\n', std(differences_R));
    fprintf('Range: %.3f to %.3f\n', min(differences_R), max(differences_R));
    
    % Left eye
    fprintf('\nLeft Eye:\n');
    fprintf('Mean difference: %.3f\n', mean(differences_L));
    fprintf('SD of differences: %.3f\n', std(differences_L));
    fprintf('Range: %.3f to %.3f\n', min(differences_L), max(differences_L));
    
    % Binocular
    fprintf('\nBinocular:\n');
    fprintf('Mean difference: %.3f\n', mean(differences_B));
    fprintf('SD of differences: %.3f\n', std(differences_B));
    fprintf('Range: %.3f to %.3f\n', min(differences_B), max(differences_B));
end