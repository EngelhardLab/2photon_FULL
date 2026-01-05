function VelFiberBuffer(src, event)

global data_buffer timestamps_buffer size_hardware_buffer new_data_ctr 

data_buffer = circshift(data_buffer,size_hardware_buffer,1);
data_buffer (1:size_hardware_buffer,: ) = flipud(single(event.Data(1:size_hardware_buffer ,:)));

timestamps_buffer = circshift(timestamps_buffer,size_hardware_buffer );
timestamps_buffer (1:size_hardware_buffer ) = flipud(single(event.TimeStamps(1:size_hardware_buffer )));

new_data_ctr = new_data_ctr+1;


