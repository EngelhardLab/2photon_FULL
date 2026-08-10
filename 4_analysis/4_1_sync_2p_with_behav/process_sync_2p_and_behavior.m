function frames_behav_time_vec = process_sync_2p_and_behavior(imaging_folder,behav_file)

if imaging_folder(end)~='\'
    imaging_folder = [imaging_folder,'\'];
end

syncdata_folder = [imaging_folder,'syncdata'];
if ~exist(syncdata_folder ,'dir')
    mkdir(syncdata_folder);
end

syncdata_folder = [syncdata_folder,'\'];

if ~exist([syncdata_folder,'csvdata.mat'],'file')
    acsv = dir([imaging_folder,'*.csv']);
    csv_data = readtable([acsv.folder,'\',acsv.name]);
    save([syncdata_folder,'csvdata.mat'],'csv_data','-v7.3')
else
    load([syncdata_folder,'csvdata.mat'],'csv_data')
end
%TODO: find which blocks of the behavioral log file belong to the current csv file

if ~exist([syncdata_folder,'behav_sync_times.mat'],'file')
    [behav_sync_times , NS_times] = get_sync_times(behav_file,csv_data);
    if ~isempty(NS_times)
       [behav_sync_times, NS_times] =  fix_sync_signal(behav_sync_times,NS_times);

    end
    if strcmp(behav_file(end-69:end),'PoissonBlocksShapingC_Cohort6_Engelhard_2p_floor2_m1991_T_20240807.mat')
        behav_sync_times = behav_sync_times(1:14032);
    end
    if strcmp(behav_file(end-69:end),'PoissonBlocksShapingC_Cohort5_Engelhard_2p_floor2_m9895_T_20251209.mat')
    behav_sync_times = behav_sync_times(1:21884);
     % Verify the truncation actually aligned the arrays
    if numel(behav_sync_times) == numel(NS_times)
        r = diff(NS_times) ./ diff(behav_sync_times);
        n_bad = sum(abs(r - median(r))/median(r) > 0.01);
        fprintf('[m9895 09122025 truncate] outliers >1%%: %d (should be ~0)\n', n_bad);
    end
end
    save([syncdata_folder,'behav_sync_times.mat'],'behav_sync_times','NS_times')
else
    load([syncdata_folder,'behav_sync_times.mat'],'behav_sync_times','NS_times')
end

xxd = dir([imaging_folder,'*.xml']);

if ~exist([syncdata_folder,'frames_2p_timevec.mat'],'file')
    xml_file = fileread([xxd(1).folder,'\',xxd(1).name]);
    frames_2p_time_vec = get_2p_frames_times(xml_file);
    save([syncdata_folder,'frames_2p_timevec.mat'],'frames_2p_time_vec')
else
    load([syncdata_folder,'frames_2p_timevec.mat'],'frames_2p_time_vec')
end

if ~isempty(NS_times)
    frames_behav_time_vec = interp1(NS_times+22.5,behav_sync_times,frames_2p_time_vec*1e3,'linear','extrap');
else
    frames_behav_time_vec =[];
end

%sanity check with reward times
if strcmp(behav_file(end-69:end),'PoissonBlocksShapingC_Cohort5_Engelhard_2p_floor2_m9402_T_20250320.mat')
    csv_data.Input1(2.04e6:2.07e6)=0;
end
[rw_times,end_trial_times_2p,end_trial_times_rw] = check_rw_times_2p_behav(behav_file,csv_data,frames_behav_time_vec,frames_2p_time_vec);
if strcmp(behav_file(end-69:end),'PoissonBlocksShapingC_Cohort6_Engelhard_2p_floor2_m1991_T_20240807.mat') ||...
     strcmp(behav_file(end-69:end),'PoissonBlocksShapingC_Cohort6_Engelhard_2p_floor2_m9020_T_20240808.mat') ||...
          strcmp(behav_file(end-69:end),'PoissonBlocksShapingC_Cohort5_Engelhard_2p_floor2_M9020_T_20240902.mat') ||...
           strcmp(behav_file(end-69:end),'PoissonBlocksShapingC_Cohort5_Engelhard_2p_floor2_M9020_T_20240818.mat') ||...
            strcmp(behav_file(end-69:end),'PoissonBlocksShapingC_Cohort5_Engelhard_2p_floor2_M9020_T_20240822.mat')

    end_trial_times_2p = end_trial_times_2p(1:end-1);
    end_trial_times_rw = end_trial_times_rw(1:end-1);
end

if ~isempty(end_trial_times_2p)
    median_error_sec = median(abs(rw_times'-end_trial_times_2p));
    max_error_sec = max(abs(rw_times'-end_trial_times_2p));

    disp(['Median error (sec): ',num2str(median_error_sec),'.  Max error (sec): ',num2str(max_error_sec)])
    %now add the reward times to the interpolation

    % frames_behav_time_vec = interp1([NS_times+22.5; repmat(rw_times*1e3,10,1).*reshape(repmat(((1:10)-5.49)*1e-10,length(rw_times),1),10*length(rw_times),1)],[behav_sync_times; repmat(end_trial_times_rw',10,1)],frames_2p_time_vec*1e3,'linear','extrap');
    %    frames_behav_time_vec = interp1([NS_times+22.5; rw_times*1e3],[behav_sync_times; end_trial_times_rw'],frames_2p_time_vec*1e3,'linear','extrap');
%     inds_for_rw = setdiff(1:length(rw_times),[find(ismember(rw_times*1e3,NS_times+22.5)) find(ismember(end_trial_times_rw,behav_sync_times))]);
%     frames_behav_time_vec = interp1([NS_times+22.5; rw_times(inds_for_rw)*1e3],[behav_sync_times; end_trial_times_rw(inds_for_rw)'],frames_2p_time_vec*1e3,'linear','extrap');

    inds_for_synctimes= setdiff(1:length(NS_times),[find(ismember(NS_times+22.5,rw_times*1e3)); find(ismember(behav_sync_times,end_trial_times_rw))]);
    frames_behav_time_vec = interp1([NS_times(inds_for_synctimes)+22.5; rw_times*1e3],[behav_sync_times(inds_for_synctimes); end_trial_times_rw'],frames_2p_time_vec*1e3,'linear','extrap');

else

    disp('Sync signal not saved, using reward times only')
    try
    frames_behav_time_vec = interp1(rw_times*1e3,end_trial_times_rw',frames_2p_time_vec*1e3,'linear','extrap');

    catch
        disp('')
    end
end

save([syncdata_folder,'rw_times.mat'],'rw_times','end_trial_times_2p','end_trial_times_rw');

save([syncdata_folder,'frames_behav_time_vec.mat'],'frames_behav_time_vec');

