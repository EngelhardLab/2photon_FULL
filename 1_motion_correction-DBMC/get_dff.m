% arguments: cur_trace        - the fluorescence trace to be processed.
%            samp_freq        - the sampling frequency of the trace.
%            seconds_for_fnot – window size for calculating the baseline fluorescence.
%            do_filter        – smooth the fluorescence before processing.


function dff = get_dff(cur_trace,samp_freq,seconds_for_fnot,do_filter)
if nargin<2
    samp_freq=15;
end
if nargin<3
    seconds_for_fnot=60;
end
if nargin<4
    do_filter=1;
end
cur_trace = cur_trace(:);

if do_filter
    temp = filtfilt(normpdf(-10:10,0,3*samp_freq/30),1,cur_trace(~isnan(cur_trace)));
else
    temp = cur_trace(~isnan(cur_trace));
end

cpp = running_percentile(temp,seconds_for_fnot*samp_freq,8)';
if size(cpp,1) ~= size(temp,1)
cpp = cpp';
end
dff(~isnan(cur_trace)) = (temp-cpp)./cpp;
dff(isnan(cur_trace))  = NaN;