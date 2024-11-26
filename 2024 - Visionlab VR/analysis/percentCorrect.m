% Load JSON data
filename = 'sub-010_ecc-5-01.json';
data = jsondecode(fileread(filename));

% Initialize counters
totalTrials = length(data);
correctTrials = 0;

% Loop through each trial and count correct answers
for i = 1:totalTrials
    if strcmp(data(i).CorrectOption, data(i).GuessedOption)
        correctTrials = correctTrials + 1;
    end
end

% Calculate percentage of correct answers
percentageCorrect = (correctTrials / totalTrials) * 100;

% Display the result
fprintf('Percentage of correct answers: %.2f%%\n', percentageCorrect);