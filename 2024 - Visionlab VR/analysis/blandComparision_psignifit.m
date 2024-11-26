% Select visualization type: 'acuity' or 'contrast'
visualization_type = 'acuity';  % Toggle between 'acuity' and 'contrast'

% Get first 12 participants
n_participants = 12;
subjects = {'002', '004', '005', '006', '007', '008', '009', '010', '011', '013', '014', '015'};

% Read chart data from CSV files
data1 = readtable('../data/spreadsheet/session_1.csv', 'HeaderLines', 2);
data2 = readtable('../data/spreadsheet/session_2.csv', 'HeaderLines', 2);

% Initialize arrays for VR data
vr_R = zeros(n_participants * 2, 1);  % *2 for both sessions
vr_L = zeros(n_participants * 2, 1);
vr_B = zeros(n_participants * 2, 1);

% Process VR data for each subject using psignifit
for i = 1:n_participants
    subject = subjects{i};
    
    % Process both sessions
    for s = 1:2
        sess = sprintf('0%d', s);
        idx = i + (s-1)*n_participants;  % Index for storing results
        
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
                
                % Store threshold
                threshold = result.Fit(1);
                if strcmp(cond, 'Right')
                    vr_R(idx) = threshold;
                elseif strcmp(cond, 'Left')
                    vr_L(idx) = threshold;
                else
                    vr_B(idx) = threshold;
                end
            end
        else
            fprintf('File not found: %s\n', data_file);
        end
    end
end

% Get chart data for both sessions
if strcmp(visualization_type, 'acuity')
    chart_R = [data1.ETDRS_uncorr_R(1:n_participants); data2.ETDRS_uncorr_R(1:n_participants)];
    chart_L = [data1.ETDRS_uncorr_L(1:n_participants); data2.ETDRS_uncorr_L(1:n_participants)];
    chart_B = [data1.ETDRS_uncorr_B(1:n_participants); data2.ETDRS_uncorr_B(1:n_participants)];
    
    x_label = 'Mean of Chart and VR (logMAR)';
    y_label = 'Difference (Chart - VR)';
    plot_title = 'Bland-Altman Plot: Chart vs VR Visual Acuity (Both Sessions)';
else
    chart_R = [data1.Pelli_corr_R(1:n_participants); data2.Pelli_corr_R(1:n_participants)];
    chart_L = [data1.Pelli_corr_L(1:n_participants); data2.Pelli_corr_L(1:n_participants)];
    chart_B = [data1.Pelli_corr_B(1:n_participants); data2.Pelli_corr_B(1:n_participants)];
    
    x_label = 'Mean of Chart and VR (log units)';
    y_label = 'Difference (Chart - VR)';
    plot_title = 'Bland-Altman Plot: Chart vs VR Contrast Sensitivity (Both Sessions)';
end

% Remove any NaN pairs
valid_R = ~isnan(chart_R) & ~isnan(vr_R);
valid_L = ~isnan(chart_L) & ~isnan(vr_L);
valid_B = ~isnan(chart_B) & ~isnan(vr_B);

chart_R = chart_R(valid_R); vr_R = vr_R(valid_R);
chart_L = chart_L(valid_L); vr_L = vr_L(valid_L);
chart_B = chart_B(valid_B); vr_B = vr_B(valid_B);

% Calculate overall limits for consistent axes
all_means = [(chart_R + vr_R)/2; (chart_L + vr_L)/2; (chart_B + vr_B)/2];
all_diffs = [chart_R - vr_R; chart_L - vr_L; chart_B - vr_B];

if strcmp(visualization_type, 'acuity')
    % Fixed x-axis limits for acuity
    x_min = -0.3;
    x_max = 1.0;
else
    x_min = floor(min(all_means)*10)/10;
    x_max = ceil(max(all_means)*10)/10;
end

y_min = floor(min(all_diffs)*10)/10 - 0.2;  % Added extra space
y_max = ceil(max(all_diffs)*10)/10 + 0.2;   % Added extra space

% Create single figure
figure('Position', [100 100 800 600]);

% Colors for each condition
right_color = 'r';
left_color = 'b';
bino_color = [0.5 0 0.5]; % purple

% Create Bland-Altman plot
createBlandAltmanPlot(chart_R, vr_R, 'Right Eye', right_color, ...
                      chart_L, vr_L, 'Left Eye', left_color, ...
                      chart_B, vr_B, 'Binocular', bino_color, ...
                      x_label, y_label, x_min, x_max, y_min, y_max, plot_title, ...
                      visualization_type);

function createBlandAltmanPlot(chart_R, vr_R, titleR, colorR, ...
                              chart_L, vr_L, titleL, colorL, ...
                              chart_B, vr_B, titleB, colorB, ...
                              x_label, y_label, x_min, x_max, y_min, y_max, plot_title, ...
                              visualization_type)
    % Calculate differences and means for each condition
    differences_R = chart_R - vr_R;
    means_R = (chart_R + vr_R) / 2;
    differences_L = chart_L - vr_L;
    means_L = (chart_L + vr_L) / 2;
    differences_B = chart_B - vr_B;
    means_B = (chart_B + vr_B) / 2;
    
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
    
    % Draw connecting lines first (before points)
    for i = 1:length(means_R)
        % Connect Right to Binocular
        plot([means_R(i) means_B(i)], [differences_R(i) differences_B(i)], ...
             'Color', [0.7 0.7 0.7], 'LineWidth', 0.5, 'HandleVisibility', 'off');
        % Connect Binocular to Left
        plot([means_B(i) means_L(i)], [differences_B(i) differences_L(i)], ...
             'Color', [0.7 0.7 0.7], 'LineWidth', 0.5, 'HandleVisibility', 'off');
    end
    
    % Plot points on top of lines
    scatter(means_R, differences_R, 100, colorR, 'filled', ...
            'MarkerFaceAlpha', 0.7, 'DisplayName', titleR);
    scatter(means_L, differences_L, 100, colorL, 'filled', ...
            'MarkerFaceAlpha', 0.7, 'DisplayName', titleL);
    scatter(means_B, differences_B, 100, colorB, 'filled', ...
            'MarkerFaceAlpha', 0.7, 'DisplayName', titleB);
    
    % Add reference lines with increased font size and line width
    yline(meanDiff, 'k-', sprintf('Mean = %.2f', meanDiff), 'LineWidth', 2, 'FontSize', 20);
    yline(upperLimit, 'k--', sprintf('+1.96 SD = %.2f', upperLimit), 'LineWidth', 2, 'FontSize', 20);
    yline(lowerLimit, 'k--', sprintf('-1.96 SD = %.2f', lowerLimit), 'LineWidth', 2, 'FontSize', 20);
    yline(0, 'k:', 'LineWidth', 2); % Zero line
    
    % Set axes limits
    xlim([x_min x_max]);
    ylim([y_min y_max]);
    
    % Labels and title
    xlabel(x_label);
    ylabel(y_label);
    title(plot_title, 'FontSize', 20);
    grid on;
    legend('Location', 'best');
    
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
    
    % Calculate and print ICC
    try
        % Combine all data for ICC calculation
        method1 = [chart_R; chart_L; chart_B];
        method2 = [vr_R; vr_L; vr_B];
        
        % Calculate ICC
        [r, LB, UB, F, df1, df2, p] = ICC([method1, method2], 'A-1', 0.05);
        
        fprintf('\nIntraclass Correlation Coefficient (ICC):\n');
        fprintf('ICC: %.3f\n', r);
        fprintf('95%% CI: (%.3f to %.3f)\n', LB, UB);
        fprintf('F-test: F(%.0f,%.0f) = %.3f, p = %.4f\n', df1, df2, F, p);
    catch
        fprintf('\nCould not calculate ICC - check if ICC.m is in your path\n');
    end
end