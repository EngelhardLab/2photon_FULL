function [behav_sync_times_tmp, NS_times_tmp] =  fix_sync_signal(behav_sync_times,NS_times)


behav_sync_times_tmp = behav_sync_times;
NS_times_tmp = NS_times;

%
max_shift = length(behav_sync_times)-length(NS_times);
clear frf
if max_shift > 0
    for m=1:max_shift
        frf(m) = corr(diff(behav_sync_times(m:m+length(NS_times)-1)),diff(NS_times));
    end
    [maxval,maxind] = max(frf);
    if maxval > 0.99
        behav_sync_times_tmp = behav_sync_times(maxind:maxind+length(NS_times)-1);
    end
end
%

error_threshold = 10;
if length(behav_sync_times)==15160
    error_threshold = 8.7;
end

while 1
    try
    all_errs = find(abs(diff(1e3*behav_sync_times_tmp(1:length(NS_times_tmp)))-diff(NS_times_tmp)) > error_threshold);
    catch

        disp('')
    end

%     if all_errs(1)>14200
%         disp('')
%     end

    if (isempty(all_errs))
        break
    end
    try
    if abs(sum(diff(1e3*behav_sync_times_tmp(all_errs(1):all_errs(1)+2))) - sum(diff(NS_times_tmp(all_errs(1):all_errs(1)+2)))) < error_threshold || length(NS_times_tmp) == length(behav_sync_times_tmp)  %&&...
%            abs(diff(behav_sync_times_tmp(all_errs(1)+2:all_errs(1)+3)) - diff(NS_times_tmp(all_errs(1)+2:all_errs(1)+3)))<10
        NS_times_tmp = [NS_times_tmp(1:all_errs(1));NS_times_tmp(all_errs(1)+2:end)];
    end
    catch
        disp('')
    end
        behav_sync_times_tmp = [behav_sync_times_tmp(1:all_errs(1));behav_sync_times_tmp(all_errs(1)+2:end)];
end


if length(behav_sync_times_tmp) > length(NS_times_tmp)
behav_sync_times_tmp = behav_sync_times_tmp(1:length(NS_times_tmp));
end
if corr(diff(behav_sync_times_tmp),diff(NS_times_tmp)) < 0.99
    warning(' behav and 2p sync signals seem unaligned! ')

end




