function reward_curves(corrected_folder,syncfolder)
%07/07
%upload> A (00_all_dffs), bhv folder, from syncfolder>
%frames_behav_time_vec , rw_times, frames_2p_time_vec

slashind = '\';
if isunix
    slashind ='/';
end

%%folder with scripts used to manipulate the behaviour data
%just in case                       %% CHANGE TO THE PATH ON YOUR COMPUTER !!
try
    addpath(genpath('C:\Users\EngelhardBlab\OneDrive - Technion\Lab\software\VirRMen_bezos_sep17')) %to be able to read the behv data
catch
    disp('assuming path to VirRMen was added beforehand ...')
end
savefolder = [corrected_folder,slashind,'actv_nns',slashind];

if ~exist(savefolder,'dir')
    mkdir(corrected_folder,[slashind,'actv_nns',slashind]);
end


if nargin < 2 
    syncfolder = [corrected_folder,slashind,'behv_n_sync'];
end

load([corrected_folder,slashind,'000_all_dffs_session.mat']); % contains A

bhv = dir([syncfolder,slashind,'PoissonBlocksShapingC_Cohort5','*.mat']);
load([bhv.folder,slashind,bhv.name]);

date_sess = bhv.name(59:end-4);
date_sess = [date_sess(7:end),date_sess(5:6),date_sess(1:4)];

load([syncfolder, slashind,'syncdata', slashind,'frames_behav_time_vec.mat']);
load([syncfolder, slashind,'syncdata', slashind,'rw_times.mat']);
load([syncfolder, slashind,'syncdata', slashind,'frames_2p_timevec.mat']);

frames_behav_time_vec_ds = frames_behav_time_vec(1:2:end);


t_axis = -3:0.1:3;

for trialctr = 1:length(log.block(end).trial)
	[ind_reward, ~] = size(log.block(end).trial(trialctr).position); %index reward

	current_reward_time = log.block(end).trial(trialctr).time(ind_reward)+log.block(end).trial(trialctr).start;
	
	cur_t_axis = t_axis + current_reward_time;
	
	for cellctr = 1:length(A)
	
	Activity_around_reward(trialctr,:,cellctr) = interp1(frames_behav_time_vec_ds,A{cellctr},cur_t_axis);
	
	end

end

successful_trials = [log.block(end).trial.trialType]==[log.block(end).trial.choice];
fig = figure('visible','off');
hold on
xline(0);
for l=1:length(A)
    
	plot(t_axis,mean(Activity_around_reward(successful_trials==1,:,l),"omitnan"));%shg;pause
end
legend(labels,'Location','bestoutside');
%hold off
%legend("Neurona " + (1:length(A)), 'Location', 'bestoutside')
set(fig, 'Units', 'normalized')
set(fig, 'Position', [0.1 0.1 0.4 0.4])
title(['Activity around reward session ',])
exportgraphics(fig, [savefolder,'activity_around_reward.png'],  'ContentType', 'vector', 'Resolution', 600);
%exportgraphics(fig, [corrected_folder,slashind,'actv_nns',slashind,'activity_around_reward.png'], 'Resolution', 600);  % 300 dpi
hold off

frames_2p_time_vec_ds = frames_2p_time_vec(1:2:end);
for l=1:length(rw_times)
    [~,minind] = min(abs(rw_times(l)-frames_2p_time_vec_ds));
    rw_inds(l) = minind;
end

%for l=1:length(rw_times)
for l=1:size(Activity_around_reward,3)
    fig_err = figure('visible','off');
    
    try
    hold on
    xline(0);
	errorbar(t_axis,mean(Activity_around_reward(successful_trials==1,:,l),"omitnan"),std(Activity_around_reward(successful_trials==1,:,l),'omitnan')/sqrt(sum(successful_trials==1)));%shg;pause
    title(['n#',num2str(l),' error bars reward'])
    exportgraphics(fig_err, [savefolder,num2str(l),'_error_bars_reward.png'], 'Resolution', 300);  % 300 dpi
    catch
        disp('')
    end    
    hold off
    
end


for n_i = 1 : length(A)
    
    fig = figure('visible','off');
    hold on
    plot(frames_2p_time_vec_ds,A{n_i});   % TOTAL
    %plot(rw_times,ones(1,length(rw_times))*0.5,'r*');shg;pause    
    plot(rw_times,A{n_i}(rw_inds),'r*');%shg;pause
    set(fig, 'Units', 'normalized')
    set(fig, 'Position', [0.1 0.1 0.9 0.9])
    title(['n#',num2str(n_i),' activity w/ reward dots'])
    exportgraphics(fig, [savefolder,num2str(n_i),'_actv_rw.png'], 'Resolution', 300);  % 300 dpi
    hold off
end