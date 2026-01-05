
function make_traces(savefolder,tif_files_prefix,roi_files_cell,savesubfolder)
%savefolder - where cellpatches were saved
%tif_files_prefix - patch name <ex> : '\mc_image_stack_full_patch_1' remember to add slash
%roi_files_cell - unzipped folder of ROIs? path in a cell
%savesubfolder - where to save all traces

if nargin<4
    savesubfolder=[];
end

if contains(savesubfolder,savefolder)
    savesubfolder = extractAfter(savesubfolder,savefolder);
end

a1= datetime;
                
single_filename = [savefolder,tif_files_prefix,'.tif'];
if exist (single_filename ,'file')
    tiflist_full{1}= single_filename;
else
   multfiles = dir([savefolder,tif_files_prefix,'_part*.tif']);
   for i=1:length(multfiles)
       tiflist_full{i}= [savefolder,tif_files_prefix,'_part',num2str(i),'.tif'];
   end
end
    
InfoImage=imfinfo(tiflist_full{1});%todos tienen las mismas dimesiones/toma cualquiera
mImage=InfoImage(1).Width;
nImage=InfoImage(1).Height;

for k=1:length(roi_files_cell)
    sROI = ReadImageJROI(roi_files_cell{k});
    cur_mask_cell{k}=make_mask_from_roi(sROI,[nImage mImage])>0;
    if length(roi_files_cell)==1
        roi_name{k} = [ tif_files_prefix,'_ROI_0000-0001'];
    else
        roi_name{k} = [ tif_files_prefix,'_ROI_',sROI.strName];
    end
    
    num_pixels_in_mask(k) = sum(sum(cur_mask_cell{k}));
    %     traces_cell{k} = [];
end

% also average every X frames and save movie to test for drift
% avg_frame_ctr = 1;
% avg_frame_lim = 500;
% avg_movie     = [];
% cur_avg_frame = zeros(nImage,mImage);

for i=1:length(tiflist_full)
    filename=tiflist_full{i};
     
    %InfoImage=imfinfo(filename);
    [ImageStack,InfoImage] = loadTiffStack_single([filename]); %ImageStack is a new variable result of loadTiff
    

    NumberImages=size(ImageStack,3);
    for k=1:length(roi_files_cell)
        cur_trace_cell{k} = gpuArray.zeros(NumberImages,1); %dpu
    end
    for j=1:NumberImages
        
        for k=1:length(roi_files_cell)
            cur_trace_cell{k}(j) = sum(sum(double(ImageStack(:,:,j)).*cur_mask_cell{k}));
        end
        

    end
    for k=1:length(roi_files_cell)
        %         traces_cell{k} = [traces_cell{k} ; cur_trace_cell{k}];
        traces_cell{k}{i} = cur_trace_cell{k}/num_pixels_in_mask(k);
    end
end


%replacing fluorescense value with NaNs where cell stops being visible

txt_isvisible = [savefolder,'Patch_',tif_files_prefix(27:end),'_visible.txt'];
    

if exist(txt_isvisible,'file')
    cell_visible_lines = readlines(txt_isvisible,"EmptyLineRule","skip");
    total_frames = 0;
    
    for k=1:length(roi_files_cell)
        trace = traces_cell{k};

        for i=1:length(trace)
            total_frames = total_frames + length(trace{i}) ;
        end

        n_frames_AVG_500 = ceil(total_frames/500);      
        
        from_fr = str2num(extractBefore(cell_visible_lines(k),'-'));
        from_fr = (from_fr - 1) * 500 + 1 ;

        to_fr = str2num(extractAfter(cell_visible_lines(k),'-'));                
        if to_fr == n_frames_AVG_500
            to_fr = round( total_frames * to_fr / n_frames_AVG_500 ); 
        else 
            to_fr = to_fr * 500;
        end

        ctr_frames = 0 ;
        for i=1:length(trace)
            flagg = 0;
            if ctr_frames< from_fr && from_fr < length(trace{i})+ctr_frames
                if from_fr-ctr_frames > 1 
                    trace{1,i}(1:from_fr-ctr_frames)=nan;
                end
                flagg = 1;
            end

            if ctr_frames< to_fr && to_fr < length(trace{i})+ctr_frames
                 trace{1,i}(to_fr-ctr_frames+1:end)=nan;
                 flagg = 1;
            end

            
            if length(trace{i})+ctr_frames < from_fr | length(trace{i})+ctr_frames > to_fr  && flagg == 0
                 trace{1,i}(:)=nan;
            end


            ctr_frames = ctr_frames + length(trace{i});
        end

        save([savefolder,savesubfolder,roi_name{k}],'trace')
    end

else 
    disp(['[Patch #',tif_files_prefix(27:end),'] >> visible.txt was not found, skipping...'])
    if ~isempty(savesubfolder)

        for k=1:length(roi_files_cell)

            trace = traces_cell{k};
            save([savefolder,savesubfolder,roi_name{k}],'trace')

        end
    else
        for k=1:length(roi_files_cell)

            trace = traces_cell{k};
            save([savefolder,roi_name{k}],'trace')
        end
    end
end
a2 = datetime;
disp(['[Patch #',tif_files_prefix(27:end),'] >>Elapsed time : ',char(a2-a1)]);