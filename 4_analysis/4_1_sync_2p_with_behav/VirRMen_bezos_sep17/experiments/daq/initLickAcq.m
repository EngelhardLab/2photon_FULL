function initLickAcq()
global curlickbuffer curlickbuffer_timestamps size_hardware_lickbuffer new_lickdata_ctr s lh sync_localtime_licktime

s = daq.createSession('ni');
addAnalogInputChannel(s,'Dev1', 0, 'Voltage');
s.Rate = 200;

size_hardware_lickbuffer = 100; %change virmenEngine.m line 87 appropriately
buffersize = 60*10*s.Rate;

curlickbuffer            = single(zeros(buffersize,1)); %5min
curlickbuffer_timestamps = single(zeros(buffersize,1)); %5min
new_lickdata_ctr         = 0;
sync_localtime_licktime  = single(zeros(ceil(buffersize/size_hardware_lickbuffer),2)); %5min

lh = addlistener(s,'DataAvailable', @lickbuffer);
s.NotifyWhenDataAvailableExceeds = size_hardware_lickbuffer;
s.IsContinuous = true;
s.startBackground();