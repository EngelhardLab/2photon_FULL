% test for correct 2p file conversion
function [status_vec,a, mm] = test_2p_file_conversion(topfolder)

a = dir([topfolder,'/TSeries*']);

if isempty(a)
    error('No T-Series in directory provided')
end

status_vec = zeros(1,length(a)); % all good

for dirctr = 1:length(a)
    if ~a(dirctr).isdir
        status_vec(dirctr) = -1; %not relevant
        break
    end

    folder = [topfolder,'\',a(dirctr).name];

    xmlfile = dir([folder,'\',folder(find(folder=='\',1,'last')+1:end),'.xml']);

    if isempty(xmlfile)
        status_vec(dirctr) = 2; % no xml file
        break
    end

    text = fileread([xmlfile.folder,'\',xmlfile.name]);
    index_ind=strfind(text,'index');
    cur_quotes = find(text(index_ind:end)=='"',2,'first');

    num_indexes = str2double(text(index_ind(end)+cur_quotes(1):index_ind(end)+cur_quotes(2)-1));

    ch1_files = dir([folder,'\*Ch1*.tif']);
    ch2_files = dir([folder,'\*Ch2*.tif']);

    if length(ch1_files) < num_indexes || length(ch2_files) < num_indexes
        status_vec(dirctr) = 3; % not all frames accounted for
        break
    end

    if isempty(dir([folder,'\*.csv']))
        status_vec(dirctr) = 4; % no voltage recording csv file
        break
    end


    b2 = text(end-1000:end);
    rlind=strfind(b2,'relativeTime');
    b3 = b2(rlind+14:rlind+40);
    relTime = str2double(b3(1:find(b3=='"',1,'first')-1));

    warning off all
    acsv = dir([folder,'\*.csv']);
    c = readtable([folder,'\',acsv.name]);
    warning on all

    length_diff = c.Time_ms_(end)/1e3*20e3-size(c,1);

    axml = dir([folder,'\*.xml']);
    bx = fileread([folder,'\',axml(2).name]);
    bx2 = bx(end-1000:end);
    rlind=strfind(bx2,'SamplesAcquired');
    bx3 = bx2(rlind(1)+16:rlind(2)-3);
    NumCSVSamples= str2double(bx3);

    if height(c) ~= NumCSVSamples || length_diff>1e3
        status_vec(dirctr) = 5; % problem in csv file
        break

    end

    tiffdir = dir([folder,'\*.tif']);
    clear tiffsizes
    for tffctr = 1:length(tiffdir)
        tiffsizes(tffctr) = tiffdir(tffctr).bytes;
    end

    if max(tiffsizes)>2e9 && sum(tiffsizes<2e9)>3
        status_vec(dirctr) = 6; % pssible truncated multipage tiff files due to bad conversion
        break

    end

end





if sum(status_vec>0)==0
    mm = [topfolder,' correctly converted'];
else
    mm = ['Detected a problem in the conversion of ',topfolder];
end