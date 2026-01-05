function lickbuffer(src, event)
% persistent tempctr
global curlickbuffer curlickbuffer_timestamps size_hardware_lickbuffer new_lickdata_ctr sync_localtime_licktime
% if isempty(tempctr)
%     tempctr=1;
% end
sync_localtime_licktime(new_lickdata_ctr+1,:) = [cputime event.TimeStamps(size_hardware_lickbuffer)];

curlickbuffer = circshift(curlickbuffer,size_hardware_lickbuffer );
curlickbuffer (1:size_hardware_lickbuffer ) = flipud(single(event.Data(1:size_hardware_lickbuffer )));

curlickbuffer_timestamps = circshift(curlickbuffer_timestamps,size_hardware_lickbuffer );
curlickbuffer_timestamps (1:size_hardware_lickbuffer ) = flipud(single(event.TimeStamps(1:size_hardware_lickbuffer )));

new_lickdata_ctr = new_lickdata_ctr+1;

% tempctr=tempctr+1;
% if tempctr>200
%    disp( num2str(event.Data(1:size_hardware_lickbuffer)))
%    tempctr=1;
% end


% if new_lickdata_ctr==100
%    disp(num2str(new_lickdata_ctr)) 
% end




