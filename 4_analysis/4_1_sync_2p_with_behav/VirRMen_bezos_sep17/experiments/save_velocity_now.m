%initialize vr struct and start saving velocities


%init
vr = load('C:\Experiments\VirRMen\experiments\poisson_blocks.mat');
vr.worlds = struct([]);
for wNum = 1:length(vr.exper.worlds)
    vr.worlds{wNum} = loadVirmenWorld(vr.exper.worlds{wNum});
    if size(vr.worlds{wNum}.surface.colors,1) == 4
        vr.worlds{wNum}.surface.colors(4,isnan(vr.worlds{wNum}.surface.colors(4,:))) = 1-eps;
    end
end

vr.experimentEnded = false;
vr.currentWorld = 1;
vr.position = vr.worlds{vr.currentWorld}.startLocation;
vr.velocity = [0 0 0 0];
vr.dt = NaN;
vr.dp = NaN(1,4);
vr.dpResolution = inf;
vr.collision = false;
vr.text = struct('string',{},'position',{},'size',{},'color',{},'window',{});
vr.plot = struct('x',{},'y',{},'color',{},'window',{});
vr.textClicked = NaN;
vr.keyPressed = NaN;
vr.keyReleased = NaN;
vr.buttonPressed = NaN;
vr.buttonReleased = NaN;
vr.modifiers = NaN;
vr.activeWindow = NaN;
vr.cursorPosition = NaN;
vr.iterations = 0;
vr.timeStarted = NaN;
vr.timeElapsed = 0;
vr.sensorData = [];
vr = initializeVRRig(vr);



%record velocities
freq = 85 ; % in Hz
time_period = 1/85; % sec

res_str.timevec = [];
res_str.velocity = [];
res_str.rawData = [];

disp('When done, press ctrl-c. data is in the variable res_str')

tic
while(1)
    pause(time_period)
    [velocity, rawData] = moveArduinoLiteralMEX(vr);
    res_str.timevec(end+1,1) = toc;
    res_str.velocity(end+1,:)=velocity;
    res_str.rawData(end+1,:)=rawData;
end







