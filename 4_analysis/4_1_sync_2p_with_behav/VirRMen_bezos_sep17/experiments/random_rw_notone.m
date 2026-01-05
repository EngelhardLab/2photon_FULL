nidaqI2C('end')
nidaqPulse('end')
nidaqI2C('init',RigParameters.nidaqDevice,RigParameters.nidaqPort,RigParameters.syncClockChannel,RigParameters.syncDataChannel)
nidaqPulse('init', RigParameters.nidaqDevice, RigParameters.nidaqPort, RigParameters.rewardChannel);
%LS=loadSound('left_100ms.wav', 1.2);
LS=loadSound('C:\Ben\stereo_1sec_new.wav', 1.2);

%%%

% conditioning

disp('Conditioning: tone always followed by reward')
for i=1:10
%play(LS.player)
nidaqI2C('send', uint8(2), true);
pause(1)
nidaqPulse('ttl', RigParameters.rewardDuration*1e3);
nidaqI2C('send', uint8(1), true);
pause(5+rand*10);
disp(num2str(i))
end

nidaqI2C('end')
nidaqPulse('end')