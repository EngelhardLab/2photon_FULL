function vr = rewardVRTrial(vr, rewardFactor, denyReward)
if nargin<3
    denyReward=0;
end

% Compute reward duration
if nargin > 1
    rewardMSec  = rewardFactor * vr.rewardMSec;
else
    rewardMSec  = vr.rewardMSec;
end

if RigParameters.hasDAQ
    if ~denyReward
        deliverReward(vr, rewardMSec);
    end
end

% Reward duration needs to be converted to seconds
    vr.waitTime = vr.trialEndPauseDur - rewardMSec/1000;
    vr.state    = BehavioralState.EndOfTrial;

end
