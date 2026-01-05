nidaqI2C('end')
nidaqPulse('end')
nidaqI2C('init',RigParameters.nidaqDevice,RigParameters.nidaqPort,RigParameters.syncClockChannel,RigParameters.syncDataChannel)
nidaqPulse('init', RigParameters.nidaqDevice, RigParameters.nidaqPort, RigParameters.rewardChannel);
%LS=loadSound('left_100ms.wav', 1.2);
LS=loadSound('C:\Ben\stereo_1sec_new.wav', 1.2);

%%%

% conditioning
T = 20;
fs = 16000;
t = 0:1/fs:T;
y=sin(2*pi*t*5000);

disp('Conditioning: tone always followed by reward')
pause(20)
for i=1:22


nidaqPulse('ttl', RigParameters.rewardDuration*1e3);
sound(y,fs)

%play(LS.player)
nidaqI2C('send', uint8(2), true);
%pause(1)
nidaqPulse('ttl', RigParameters.rewardDuration*1e3);
%nidaqPulse('ttl', RigParameters.rewardDuration*0);
nidaqI2C('send', uint8(1), true);

pause(90+rand*10);
disp(num2str(i))

end

nidaqI2C('end')
nidaqPulse('end')