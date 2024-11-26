config = jsondecode(fileread('config.json'));
titleId = config.titleId;
secretKey = config.secretKey;
% playFabId = config.playFabId;

playFabIds = config.playFabIds;

% Construct API URL (note the change from Client to Server)
% url = ['https://' titleId '.playfabapi.com/Server/GetUserData'];

% Set up request headers
headers = {
    'X-PlayFabSDK', 'MATLAB-1.0'
    'Content-Type', 'application/json'
    'X-SecretKey', secretKey
};

% Prepare request body
% body = struct('PlayFabId', playFabId);

% Set up options
options = weboptions('HeaderFields', headers, ...
                     'RequestMethod', 'post', ...
                     'MediaType', 'application/json');

% Iterate over each PlayFab ID

for j = 1:length(playFabIds)

    playFabId = playFabIds{j};


    % Construct API URL for getting user data

    url = ['https://' titleId '.playfabapi.com/Server/GetUserData'];


    % Prepare request body

    body = struct('PlayFabId', playFabId);


    % Make API call

    try
        response = webwrite(url, body, options);
        

        dataKeys = fieldnames(response.data.Data);


        % Define the base directory for saving data
        baseDir = fullfile('..', 'data', 'webdata', playFabId);


        % Create the directory if it doesn't exist

        if ~exist(baseDir, 'dir')

            mkdir(baseDir);
        end


        % Iterate over each key to access and save the data

        for i = 1:length(dataKeys)

            key = dataKeys{i};

            jsonData = response.data.Data.(key).Value;


            % Define the file path

            filePath = fullfile(baseDir, [key, '.json']);

            % Save the JSON data to a file

            fid = fopen(filePath, 'w');

            if fid == -1

                error('Cannot open file for writing: %s', filePath);

            end

            fprintf(fid, '%s', jsonData);

            fclose(fid);

            % Display the key and the corresponding JSON data

            disp(['Key: ', key]);

            disp(['JSON Data saved to: ', filePath]);

        end

    catch ME
        disp(['Error occurred for PlayFabId: ', playFabId]);
        disp(ME.message);

    end

end