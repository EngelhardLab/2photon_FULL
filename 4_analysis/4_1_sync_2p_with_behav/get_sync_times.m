function [behav_sync_times , NS_times] = get_sync_times(behav_file,csv_data)

d = load(behav_file);

behav_sync_times = [];
for bctr = 1:length(d.log.block)
    for tctr = 1:length(d.log.block(bctr).trial)
        behav_sync_times = [behav_sync_times;d.log.block(bctr).trial(tctr).time(find(d.log.block(bctr).trial(tctr).newSync))+d.log.block(bctr).trial(tctr).start];
    end
end

    NS_times = csv_data.Time_ms_(find(csv_data.Input0(1:end-1)<3 & csv_data.Input0(2:end)>3));



