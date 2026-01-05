function progressTable = progress_table_function(mouse_folder)
% progress_table_function
%   Scans all mouse behavior .mat files and creates a table of:
%   session date, maze type, and fraction correct (for T6 mazes).
%
% INPUT:
%   mouse_folder - path to the folder containing mouse session .mat files
%
% OUTPUT:
%   progressTable - table with Date, MazeType, and FractionCorrect

% Initialize containers
Date = datetime.empty;
mazeTypes = {};
fractioncorrect = [];
numtrials_slx_vec = [];
tot_fractioncorrect = [];
tot_numtrials_slx_vec = [];
path_ordered = {};

% Find all .mat files (sessions)
sessionData = dir(fullfile(mouse_folder, '*.mat'));

% Loop over each session
for i = 1:length(sessionData)
    sessionName = sessionData(i).name;
    sessionPath = fullfile(mouse_folder, sessionName);
    
    % Initialize default values for each session
    sessionDate = NaT;
    mazeType = 'Unknown';
    fracCorrect = NaN;
    numtrials_slx= NaN;
    tot_fracCorrect = NaN;
    tot_numtrials_slx = NaN;
    
    % Try loading 'log' struct
    try
        s = load(sessionPath, 'log');
        if ~isfield(s, 'log')
            warning('No ''log'' field found in file: %s', sessionName);
            log = [];
        else
            log = s.log;
        end
    catch
        warning('Could not load log from file: %s', sessionName);
        log = [];
    end

    % If log loaded, extract information
   if ~isempty(log)
    importDate = [str2double(sessionName(65:66)),str2double(sessionName(63:64)),str2double(sessionName(59:62))];
    sessionDate = datetime(importDate(3), importDate(2), importDate(1));
        


    % --- Get maze type ---
    mazeType_id = log.animal.experiment(60:end-4);
    if contains(mazeType_id,'linear_track')         
         if isstruct(log.animal.virmenSensor)
             mazeType = log.animal.virmenSensor.ValueNames{1};
         else 
             mazeType = [mazeType_id,'/',char(string(log.animal.virmenSensor))];
         end
    else
        mazeType = ['T-maze #',num2str(log.animal.mainMazeID)];
    end
    

    % --- Find longest session and extract trial data ---
    if isfield(log, 'block') && isfield(log.block, 'trial')
        number_of_trials = zeros(1, length(log.block));
        for e = 1:length(log.block)
            number_of_trials(e) = length(log.block(e).trial);
        end
        select_session = max(number_of_trials);
        session = find(number_of_trials == select_session, 1, 'first');
        trialData = log.block(session).trial;

        if isstruct(trialData) && ~isempty(trialData)
            numtrials = length(trialData);

            % --- Try fancy then simple ---
            if ~contains(mazeType_id, 'linear_track')
                success_vec = [trialData.trialType] == [trialData.choice];
                if length(success_vec) > 60
                    smoothed_sr = filtfilt(normpdf(-10:10,0,5), 1, double(success_vec));

                    first_trial = min([1 find(smoothed_sr(1:50) < 0.6, 1, 'last')]);
                    last_trial = max([100 find(smoothed_sr(50:end) < 0.6, 1, 'first') + 50]);
                    first_trial = max(1, first_trial);
                    last_trial = min(length(success_vec), last_trial);
                    numtrials_slx = last_trial-first_trial+1; %drn

                    if last_trial > first_trial
                        fracCorrect = mean(success_vec(first_trial:last_trial));
                    else
                        error('First trial after last trial');
                    end
                %else
                %    error('Too few trials for filtering');
                end
            
                % If anything goes wrong, use simple middle 60% method
                try
                    if numtrials > 5
                        trials_to_take = round(numtrials/5) : (numtrials - round(numtrials/5));
                        trialTypes = [trialData(trials_to_take).trialType];
                        choices = [trialData(trials_to_take).choice];
                        tot_fracCorrect = mean(trialTypes == choices);
                        tot_numtrials_slx = numtrials;
                    else
                        tot_fracCorrect  = NaN;
                        tot_numtrials_slx = numtrials;
                    end
                catch
                    warning('Could not compute simple fraction correct for file: %s', sessionName);
                    tot_fracCorrect = NaN;
                    tot_numtrials_slx = numtrials;
                end
            end
        end
    end

    % --- Save session info ---
    Date(end+1,1) = sessionDate;
    mazeTypes{end+1,1} = mazeType;
    fractioncorrect(end+1,1) = fracCorrect;
    numtrials_slx_vec(end+1,1) = numtrials_slx;
    path_ordered{end+1,1} = sessionPath;
    tot_fractioncorrect(end+1,1) = tot_fracCorrect;
    tot_numtrials_slx_vec (end+1,1) = tot_numtrials_slx;
end

% --- Create final table ---
progressTable = table(Date, mazeTypes, fractioncorrect,numtrials_slx_vec,tot_fractioncorrect,tot_numtrials_slx_vec,path_ordered, ...
    'VariableNames', {'Date', 'MazeType', 'FractionCorrect','NumTrials', 'TOTAL_FractionCorrect','TOTAL_NumTrials','Path'}); 
% Sort table by Date
progressTable = sortrows(progressTable, 'Date');


end
