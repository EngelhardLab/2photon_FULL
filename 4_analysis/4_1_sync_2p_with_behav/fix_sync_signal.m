function [behav_sync_times_tmp, NS_times_tmp] =  fix_sync_signal(behav_sync_times,NS_times)


behav_sync_times_tmp = behav_sync_times;
NS_times_tmp = NS_times;
while 1
    try
    all_errs = find(abs(diff(1e3*behav_sync_times_tmp(1:length(NS_times_tmp)))-diff(NS_times_tmp))>10);
    catch

        disp('')
    end

    % if all_errs(1)>3800
    % disp('')
    % end

    if (isempty(all_errs))
        break
    end
    if abs(sum(diff(1e3*behav_sync_times_tmp(all_errs(1):all_errs(1)+2))) - sum(diff(NS_times_tmp(all_errs(1):all_errs(1)+2))))<10 %&&...
%            abs(diff(behav_sync_times_tmp(all_errs(1)+2:all_errs(1)+3)) - diff(NS_times_tmp(all_errs(1)+2:all_errs(1)+3)))<10
        NS_times_tmp = [NS_times_tmp(1:all_errs(1));NS_times_tmp(all_errs(1)+2:end)];
    end

    behav_sync_times_tmp = [behav_sync_times_tmp(1:all_errs(1));behav_sync_times_tmp(all_errs(1)+2:end)];
end

