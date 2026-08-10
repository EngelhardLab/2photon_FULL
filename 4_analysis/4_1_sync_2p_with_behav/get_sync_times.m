function [behav_sync_times , NS_times] = get_sync_times(behav_file,csv_data)

d = load(behav_file);

behav_sync_times = [];
behav_sync_times_per_block = {};
for bctr = 1:length(d.log.block)
    behav_sync_times_per_block{bctr} = [];
    for tctr = 1:length(d.log.block(bctr).trial)
        behav_sync_times = [behav_sync_times;d.log.block(bctr).trial(tctr).time(find(d.log.block(bctr).trial(tctr).newSync))+d.log.block(bctr).trial(tctr).start];
        behav_sync_times_per_block{bctr} = [behav_sync_times_per_block{bctr};d.log.block(bctr).trial(tctr).time(find(d.log.block(bctr).trial(tctr).newSync))+d.log.block(bctr).trial(tctr).start];
    end
end

% NS_times = csv_data.Time_ms_(find(csv_data.Input0(1:end-1)<3 & csv_data.Input0(2:end)>3));
NS_times = csv_data.Time_ms_(find(csv_data.Input0(1:end-2)<3 & csv_data.Input0(2:end-1)<3 & csv_data.Input0(3:end)>3)+1);

%choose if to take all blocks, or one of the blocks, and which one.
num_syncs = length(behav_sync_times);
for bctr = 1:length(d.log.block)
    num_syncs(end+1) = length(behav_sync_times_per_block{bctr}) ;
end

[~,minind] = min(abs(length(NS_times)-num_syncs));

if minind>1
    behav_sync_times = behav_sync_times_per_block{minind-1};
end



