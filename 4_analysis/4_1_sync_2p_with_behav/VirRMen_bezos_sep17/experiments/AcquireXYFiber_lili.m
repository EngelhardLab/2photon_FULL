function AcquireXYFiber_lili()

nidaqI2C('end')
nidaqPulse('end')
nidaqI2C('init',RigParameters.nidaqDevice,RigParameters.nidaqPort,RigParameters.syncClockChannel,RigParameters.syncDataChannel)
nidaqPulse('init', RigParameters.nidaqDevice, RigParameters.nidaqPort, RigParameters.rewardChannel);
%LS=loadSound('left_100ms.wav', 1.2);
LS=loadSound('C:\Ben\stereo_1sec_new.wav', 1.2);


nidaqI2C('send', uint8(2), true);

global data_buffer timestamps_buffer size_hardware_buffer new_data_ctr s KEY_IS_PRESSED

savefolder = 'C:\Ben\Velocity_FiberPhotometry\logs';
h=datetime;
curdatetime = [num2str(h.Year),num2str(h.Month),num2str(h.Day),'_',num2str(h.Hour),'-',num2str(h.Minute),'-',num2str(round(h.Second))];
namestr = input('Enter mouse name and recording site and press enter');
savename = [savefolder,'\',curdatetime,'_',namestr,'.mat'];

initVelFiberAcq;

figure(99)
% for i=1:4
%     subplot(4,1,i)
% end
% title('Acquisition started. Press any key to stop')

set(gcf, 'KeyPressFcn', @myKeyPressFcn)
KEY_IS_PRESSED = 0;

tic
while ~KEY_IS_PRESSED
    for i=1:5       
        subplot(5,1,i)
        plot((1:s.Rate*10)/100,flipud(data_buffer(1:s.Rate*10,i)));
        if i==1
            title(['Acquiring ',num2str(round(toc)),' sec. Press any key to stop'])
        end
    end
    xlabel('Time (sec)')
    drawnow
end

% end acquisition
terminateDataAcq;
Data       = flipud(data_buffer(1:size_hardware_buffer*new_data_ctr,:));
TimeStamps = flipud(timestamps_buffer(1:size_hardware_buffer*new_data_ctr));

save(savename,'Data','TimeStamps')


function myKeyPressFcn(hObject, event)
global KEY_IS_PRESSED
KEY_IS_PRESSED  = 1;

% 
% % in another matlab window do:
% nidaqPulse('init', RigParameters.nidaqDevice, RigParameters.nidaqPort, RigParameters.rewardChannel);
% while(1)
% tic;
% pause(rand*60)
% nidaqPulse('ttl', RigParameters.rewardDuration*1e3);
% disp(['Reward delivered after ',num2str(toc),' sec.'])
% end



























