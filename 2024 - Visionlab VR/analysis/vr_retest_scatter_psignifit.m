% Select visualization type: 'acuity' or 'contrast'
visualization_type = 'contrast';  % Toggle between 'acuity' and 'contrast'

% Select method: 'vr' or 'chart'
method_type = 'vr';

% Get first 12 participants
n_participants = 12;
subjects = {'002', '004', '005', '006', '007', '008', '009', '010', '011', '013', '014', '015'};

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
    
    % Process both sessions
    for session = {'01', '02'}
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
                if strcmp(sess, '01')
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
    x_min = -0.2;
    x_max = 0.8;
else
    % Dynamic limits for contrast (adjusted for negative values)
    x_min = floor(min(all_means)*10)/10;
    x_max = ceil(max(all_means)*10)/10;
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
    x_label = 'Session 1 (logMAR)';
    y_label = 'Session 2 (logMAR)';
    plot_title = sprintf('VR Visual Acuity Test-Retest');
    % Fixed limits for acuity
    axis_min = -0.3;    % Changed from -0.2
    axis_max = 1.0;    % Changed from 0.8
else
    x_label = 'Session 1 (log units)';
    y_label = 'Session 2 (log units)';
    plot_title = sprintf('VR Contrast Sensitivity Test-Retest');
    % Fixed limits for contrast
    axis_min = -2.25;   % Changed from dynamic limit
    axis_max = -0.9;   % Changed from dynamic limit
end

% Create scatter plot
hold on;

% Plot connecting lines first (grey lines between conditions)
for i = 1:length(s1_L)
    % Connect Left to Binocular
    plot([s1_L(i), s1_B(i)], [s2_L(i), s2_B(i)], ...
         '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
    % Connect Binocular to Right
    plot([s1_B(i), s1_R(i)], [s2_B(i), s2_R(i)], ...
         '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
end

% Calculate fits and R² values
[fitR, R2_R] = fit_and_R2(s1_R, s2_R);
[fitL, R2_L] = fit_and_R2(s1_L, s2_L);
[fitB, R2_B] = fit_and_R2(s1_B, s2_B);

% Plot points with R² values in legend
scatter(s1_R, s2_R, 100, right_color, 'filled', 'MarkerFaceAlpha', 0.7, ...
    'DisplayName', sprintf('Right Eye (R² = %.2f)', R2_R));
scatter(s1_L, s2_L, 100, left_color, 'filled', 'MarkerFaceAlpha', 0.7, ...
    'DisplayName', sprintf('Left Eye (R² = %.2f)', R2_L));
scatter(s1_B, s2_B, 100, bino_color, 'filled', 'MarkerFaceAlpha', 0.7, ...
    'DisplayName', sprintf('Binocular (R² = %.2f)', R2_B));

% Plot fitted lines
x_fit = linspace(axis_min, axis_max, 100);
plot(x_fit, fitR(x_fit), '--', 'Color', right_color, 'LineWidth', 1.5, 'HandleVisibility', 'off');
plot(x_fit, fitL(x_fit), '--', 'Color', left_color, 'LineWidth', 1.5, 'HandleVisibility', 'off');
plot(x_fit, fitB(x_fit), '--', 'Color', bino_color, 'LineWidth', 1.5, 'HandleVisibility', 'off');

% Add unity line
plot([axis_min, axis_max], [axis_min, axis_max], 'k--', 'HandleVisibility', 'off');

% Set axes limits and properties
xlim([axis_min axis_max]);
ylim([axis_min axis_max]);
axis square;

% Labels and title
xlabel(x_label, 'FontSize', 20);
ylabel(y_label, 'FontSize', 20);
title(plot_title, 'FontSize', 20);
grid on;
legend('Location', 'best', 'FontSize', 16);

% Add Meta Quest reference lines for acuity
if strcmp(visualization_type, 'acuity')
    fontSize = 16;
    metaQ2 = log10(30/10);
    metaQ3 = log10(30/12.5);
    
    % Vertical and horizontal lines
    xline(metaQ2, '--', 'Meta Q2', 'LineWidth', 1, 'FontSize', fontSize, 'Color', [0.5 0.5 0.5]);
    xline(metaQ3, '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', fontSize, 'Color', [0.5 0.5 0.5]);
    yline(metaQ2, '--', 'Meta Q2', 'LineWidth', 1, 'FontSize', fontSize, 'Color', [0.5 0.5 0.5]);
    yline(metaQ3, '--', 'Meta Q3', 'LineWidth', 1, 'FontSize', fontSize, 'Color', [0.5 0.5 0.5]);
end

function [fitresult, R2] = fit_and_R2(x, y)
    % Fit linear model
    p = polyfit(x, y, 1);
    fitresult = @(x) polyval(p, x);
    
    % Calculate R-squared
    yfit = fitresult(x);
    yresid = y - yfit;
    SSresid = sum(yresid.^2);
    SStotal = sum((y - mean(y)).^2);
    R2 = 1 - SSresid/SStotal;
end