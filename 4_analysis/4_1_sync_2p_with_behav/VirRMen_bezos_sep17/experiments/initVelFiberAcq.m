function initVelFiberAcq()
global data_buffer timestamps_buffer size_hardware_buffer new_data_ctr s lh

s = daq.createSession('ni');
addAnalogInputChannel(s,'Dev1', 0:4, 'Voltage'); % x y fiber reward
s.Rate = 100; %Hz

size_hardware_buffer = 100; % 1sec hardware buffer
max_buffer_size      = 60*s.Rate*120; %two hours max recording

data_buffer       = single(zeros(max_buffer_size ,5)); %
timestamps_buffer = single(zeros(max_buffer_size ,1)); %5min
new_data_ctr      = 0;

lh = addlistener(s,'DataAvailable', @VelFiberBuffer);
s.NotifyWhenDataAvailableExceeds = size_hardware_buffer;
s.IsContinuous = true;
s.startBackground();