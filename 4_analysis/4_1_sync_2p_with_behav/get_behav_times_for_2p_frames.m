
function [frames_behav_time_vec,frames_2p_time_vec] = get_behav_times_for_2p_frames(xml_file,behav_sync_times,NS_times)

% xxd = dir([curfolder,'\*.xml']);
% xml_file = fileread([xxd(1).folder,'\',xxd(1).name]);
fifl = strfind(xml_file,'index');
cur_line = xml_file(fifl(end)-100:fifl(end)+100);

cur_segment = cur_line(strfind(cur_line,'index'):strfind(cur_line,'index')+20);
cur_quotes = find(cur_segment=='"');
last_index = str2double(cur_segment(cur_quotes(1)+1:cur_quotes(2)-1));

frames_2p_time_vec = zeros(1,last_index);
for frame_ctr = 1:last_index
    eval(['line_ind = strfind(xml_file,''index="',num2str(frame_ctr),'"'');'])
    cur_line = xml_file(line_ind(end)-100:line_ind(end)+100);
    cur_segment = cur_line(strfind(cur_line,'relativeTime'):strfind(cur_line,'relativeTime')+40);
    cur_quotes = find(cur_segment=='"');
    frames_2p_time_vec(frame_ctr) = str2double(cur_segment(cur_quotes(1)+1:cur_quotes(2)-1));    
end


frames_behav_time_vec = interp1(NS_times,behav_sync_times,frames_2p_time_vec*1e3,'linear','extrap');


