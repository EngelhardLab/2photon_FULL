function [rw_times,end_trial_times_2p,end_trial_times_rw] = check_rw_times_2p_behav(behav_file,csv_data,frames_behav_time_vec,frames_2p_time_vec)

d = load(behav_file);

end_trial_times = zeros(1,length(d.log.block(end).trial));
for tctr  = 1:length(d.log.block(end).trial)
    end_trial_times(tctr) =  d.log.block(end).trial(tctr).time(length(d.log.block(end).trial(tctr).position))+d.log.block(end).trial(tctr).start;
end

%if it is a linear track they are all rewards, if not then check when
%reward was given

if isempty(strfind(d.log.animal.experiment,'linear')) % T-maze
    end_trial_times_rw = end_trial_times(find([d.log.block(end).trial.choice]==[d.log.block(end).trial.trialType]));

else
    end_trial_times_rw = end_trial_times;
end


if ~isempty(frames_behav_time_vec)
    end_trial_times_2p = interp1(frames_behav_time_vec,frames_2p_time_vec,end_trial_times_rw,'linear');
else
    end_trial_times_2p  = [];
end

rw_inds = find(csv_data.Input1(1:end-1)<1.5 & csv_data.Input1(2:end)>1.5);
rw_times = csv_data.Time_ms_(rw_inds)/1e3;

% [rw_times'-end_trial_times_2p];









