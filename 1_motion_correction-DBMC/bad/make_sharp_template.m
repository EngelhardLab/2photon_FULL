function make_sharp_template(input_folder,output_folder,have_red_channel,use_red_channel)

error('obsolete now')
if have_red_channel
    if use_red_channel
        frames_to_take = 2;
    else
        frames_to_take = 1;
    end
else
    frames_to_take = 0;
end

if isunix
    slashind = '/';
else
    slashind = '\';
end

sharptemplate_folder = [output_folder,'sharptemplates',slashind];

load([input_folder,'chunk_info'],'num_chunks','chunks_lengths_vec','chunks_green_filenames','chunks_red_filenames')

load([output_folder,'final_xy_shifts.mat'],'XX_cell','YY_cell')

if ~exist(sharptemplate_folder ,'dir')
    mkdir(sharptemplate_folder )
end

first_frame = imread(chunks_green_filenames{1}{1});
nImage = size(first_frame,1);
mImage = size(first_frame,2);

for i=1:num_chunks
    tic
    disp(['applying pre-procesing to get sharper templates : file ',num2str(i)])
    cur_savefilename=[sharptemplate_folder,'template_',num2str(i),'.mat'];
    if exist(cur_savefilename,'file')
        continue
    end
    
    ImageStack =zeros(nImage,mImage,chunks_lengths_vec(i),'single');
    if use_red_channel
        for j=1:length(chunks_lengths_vec(i))
            ImageStack (:,:,j)=imread(chunks_red_filenames{i}{j});
        end
    else
        for j=1:length(chunks_lengths_vec(i))
            ImageStack (:,:,j)=imread(chunks_green_filenames{i}{j});
        end
    end

    ImageStack_mc=apply_mc(ImageStack,YY_cell{i},XX_cell{i});
    ImageStack_mc2=ImageStack_mc>prctile(ImageStack_mc(1:99:end),90);
    ff2=std(log(ImageStack_mc2+1),[],3)/max(max(std(log(ImageStack_mc2+1),[],3)))*255;
    cur_template = single(ff2);
    save(cur_savefilename,'cur_template')
    
    disp(['Done file ',num2str(i),' of ',num_chunks,' in ',num2str(toc),' sec.'])
    
end



