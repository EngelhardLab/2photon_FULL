function curlicks = getLicks()
persistent curindsDataTS curindsSavedata curindsSaveTS max_unread_buffers
global curlickbuffer curlickbuffer_timestamps size_hardware_lickbuffer new_lickdata_ctr


if isempty(curindsDataTS)
    max_unread_buffers =  round(12.5/ (size_hardware_lickbuffer*5))+1;
    for l=1:max_unread_buffers 
        
        curindsDataTS{l}     = (l-1)*size_hardware_lickbuffer+1:l*size_hardware_lickbuffer;
        curindsSavedata{l} = (l-1)*size_hardware_lickbuffer*2+1:(l-1)*size_hardware_lickbuffer*2+size_hardware_lickbuffer;
        curindsSaveTS{l}   = (l-1)*size_hardware_lickbuffer*2+size_hardware_lickbuffer+1:l*size_hardware_lickbuffer*2;
    end
    
end

curlicks = zeros(1,2*size_hardware_lickbuffer*max_unread_buffers,'single');

for l=1:min(new_lickdata_ctr,max_unread_buffers)
    curlicks(curindsSavedata{l}) = curlickbuffer(curindsDataTS{l});
    curlicks(curindsSaveTS{l})   = curlickbuffer_timestamps(curindsDataTS{l});
end
new_lickdata_ctr = 0;




%     curlicks(1,(l-1)*size_hardware_lickbuffer*2+1:(l-1)*size_hardware_lickbuffer*2+1) = curlickbuffer((l-1)*size_hardware_lickbuffer+1:size_hardware_lickbuffer*l);






