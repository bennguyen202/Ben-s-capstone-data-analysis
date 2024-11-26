% Read the CSV file
data1 = readtable('../../data/spreadsheet/session_1.csv', 'HeaderLines', 2);
data2 = readtable('../../data/spreadsheet/session_2.csv', 'HeaderLines', 2);

% Combine the data
ipd_values = [data1.IPD_mm_; data2.IPD_mm_];
gender = [data1.Gender; data2.Gender];

% Separate male and female data
male_ipd = ipd_values(strcmp(gender, 'M'));
female_ipd = ipd_values(strcmp(gender, 'F'));

% Remove any NaN values
male_ipd = male_ipd(~isnan(male_ipd));
female_ipd = female_ipd(~isnan(female_ipd));

% Calculate axis limits for consistency
min_ipd = floor(min([male_ipd; female_ipd]));
max_ipd = ceil(max([male_ipd; female_ipd]));
max_count = max([histcounts(male_ipd, 'BinWidth', 1), histcounts(female_ipd, 'BinWidth', 1)]);  % Changed BinWidth here

% Create figure with subplots
figure;

% Male histogram
subplot(2,1,1);
histogram(male_ipd, 'BinWidth', 1, 'FaceColor', 'b', 'FaceAlpha', 0.7);
title('Male IPD Distribution (Combined Sessions)');
xlabel('IPD (mm)');
ylabel('Frequency');
grid on;
hold on;
xline(mean(male_ipd), '--r', 'Mean', 'LineWidth', 2, 'LabelHorizontalAlignment', 'right', 'FontSize', 20); % Adjusted FontSize
xlim([min_ipd max_ipd]);
ylim([0 max_count + 1]);

% Female histogram
subplot(2,1,2);
histogram(female_ipd, 'BinWidth', 1, 'FaceColor', 'g', 'FaceAlpha', 0.7);
title('Female IPD Distribution (Combined Sessions)');
xlabel('IPD (mm)');
ylabel('Frequency');
grid on;
hold on;
xline(mean(female_ipd), '--r', 'Mean', 'LineWidth', 2, 'LabelHorizontalAlignment', 'right', 'FontSize', 20); % Adjusted FontSize
xlim([min_ipd max_ipd]);
ylim([0 max_count + 1]);

% Print statistics
fprintf('Male Statistics (Combined Sessions):\n');
fprintf('Mean IPD: %.2f mm\n', mean(male_ipd));
fprintf('Standard Deviation: %.2f mm\n', std(male_ipd));
fprintf('Number of male subjects: %d\n\n', length(male_ipd));

fprintf('Female Statistics (Combined Sessions):\n');
fprintf('Mean IPD: %.2f mm\n', mean(female_ipd));
fprintf('Standard Deviation: %.2f mm\n', std(female_ipd));
fprintf('Number of female subjects: %d\n', length(female_ipd));

% Perform t-test to compare means
[h,p] = ttest2(male_ipd, female_ipd);
fprintf('\nT-test p-value: %.4f\n', p);

% Add overall figure title
sgtitle('IPD Distribution by Gender (Combined Sessions)', 'FontSize', 14);