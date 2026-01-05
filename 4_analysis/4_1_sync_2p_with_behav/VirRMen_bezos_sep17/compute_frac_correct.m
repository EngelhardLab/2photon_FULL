function fracCorrect = compute_frac_correct(file)
% compute_frac_correct - Computes mean fraction correct based on middle 60% of trials
%
% INPUT:
%   file - .mat file for the session
%
% OUTPUT:
%   fracCorrect - mean fraction correct for selected trials
% Load the file
data = load(file);

% Extract the 'log' structure
log = data.log;
% extract the trial data
trialData = (log.block.trial);

%define the number of trials
numtrials = length(trialData);

% Define the trials to be considered for computing the frac correct
trials_to_take = round(numtrials/5) : (numtrials - round(numtrials/5));

% Define the parameters based on which the frac correct can be calculated

     trialTypes = [trialData(trials_to_take).trialType];
     choices = [trialData(trials_to_take).choice];
 % Compute fraction correct
    fracCorrect = mean(trialTypes == choices);

end
