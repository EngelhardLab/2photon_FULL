function frames_behav_time_vec = process_sync_2p_and_behavior(imaging_folder,behav_file,do_weird)

if nargin < 3
    do_weird = 0 ;
end

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
[rw_times,end_trial_times_2p,end_trial_times_rw] = check_rw_times_2p_behav(syncdata_folder,behav_file,csv_data,frames_behav_time_vec,frames_2p_time_vec,do_weird);

if ~isempty(end_trial_times_2p)
    median_error_sec = median(rw_times'-end_trial_times_2p);
    max_error_sec = max(rw_times'-end_trial_times_2p);

    disp(['Median error (msec): ',num2str(median_error_sec),'.  Max error (msec): ',num2str(max_error_sec)])
    %now add the reward times to the interpolation

    % frames_behav_time_vec = interp1([NS_times+22.5; repmat(rw_times*1e3,10,1).*reshape(repmat(((1:10)-5.49)*1e-10,length(rw_times),1),10*length(rw_times),1)],[behav_sync_times; repmat(end_trial_times_rw',10,1)],frames_2p_time_vec*1e3,'linear','extrap');
    frames_behav_time_vec = interp1([NS_times+22.5; rw_times*1e3],[behav_sync_times; end_trial_times_rw'],frames_2p_time_vec*1e3,'linear','extrap');
else

    disp('Sync signal not saved, using reward times only')

    frames_behav_time_vec = interp1(rw_times*1e3,end_trial_times_rw',frames_2p_time_vec*1e3,'linear','extrap');
    
end

save([syncdata_folder,'rw_times.mat'],'rw_times','end_trial_times_2p','end_trial_times_rw');

save([syncdata_folder,'frames_behav_time_vec.mat'],'frames_behav_time_vec');

