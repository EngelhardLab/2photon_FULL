function res=process_patch(output_folder,patch_file,patch_ctr,want_red_channel,use_red_channel,flag_downsample)

disp(['Now working on patch ',num2str(patch_ctr)])

max_shift = 30;

slashind = filesep; % Automatically handles / or \

tempfolder = [output_folder,'tempsaves',slashind];
if ~exist(tempfolder,'dir')
    mkdir(tempfolder);
end

%% Helper for Path Fixes
% Defining path correction as a nested function to avoid repetition
    function fixed_path = fix_path(p)
        fixed_path = p;
        if contains(p, 'N:\2Photon_Data')
            fixed_path = strrep(p, 'N:\2Photon_Data', '/mnt/nas/2Photon_Data/2P_Imaging_Converted_Data');
            fixed_path = strrep(fixed_path, '\', '/');
        end
    end

%% Load raw tif filenames and metadata
load([output_folder,'chunks_info'],'num_chunks','chunks_lengths_vec','chunks_green_filenames','chunks_red_filenames')

%% Check if already processed
if ~isempty(dir([output_folder,'mc_image_stack_full_patch_',num2str(patch_ctr),'*tif'])) 
    disp(['patch number (',num2str(patch_ctr),') seems to have already been processed. Quitting. '])
    res =[];
    return
end

%% Load displacement field and dimensions
load([output_folder,'demons_disp_cell.mat'],'disp_cell_summed')
mov_h=size(disp_cell_summed{1},1);
mov_w=size(disp_cell_summed{1},2);

all_patch_time=tic;
patch_struct = ReadImageJROI(patch_file);
cur_mask=make_mask_from_roi(patch_struct,[mov_h mov_w]);

cur_selection_binary = double(cur_mask>0); 
[~,cur_patch_coordinates,patch_h,patch_w] = boundingRec(cur_selection_binary);

%% Patch extraction parameters
imsize_extract = round(1.1*max([patch_h patch_w])); 
imsize_extract2=round(imsize_extract*1.2);

load([output_folder,'final_xy_shifts.mat'],'XX_cell','YY_cell')

disp(['Now working on patch ',num2str(patch_ctr),' (',patch_struct.strName,')']);

% Load templates
mc_tmu = loadTiffStack_single([output_folder,'template_mov.tif']);

disp('Extracting movie patch from mean demons displacement field...')
for chunk_ctr = 1:num_chunks
    centpatchd_mat(chunk_ctr,:) = find_center_of_displaced_patch(cur_patch_coordinates,patch_h,patch_w,disp_cell_summed{chunk_ctr});
    row_patch_start_vec(chunk_ctr) = round(centpatchd_mat(chunk_ctr,2)-patch_h/2);
    col_patch_start_vec(chunk_ctr) = round(centpatchd_mat(chunk_ctr,1)-patch_w/2);
end

[rtv_patch,ctv_patch] = mc_rigid_submovie_from_movie(mc_tmu,1,3,max_shift,0.2,1,1,-1,[patch_h patch_w],row_patch_start_vec,col_patch_start_vec,imsize_extract);
centpatchd_mat2=centpatchd_mat-[rtv_patch' ctv_patch'];

start_chunk_ctr=1;
files_saved = dir([tempfolder,'mc_stack_temp_patch_',num2str(patch_ctr),'_file_*']);
if ~isempty(files_saved)
    start_chunk_ctr=length(files_saved)+1;
    load([tempfolder,'curres_',num2str(patch_ctr)],'res');
end

threshold_before_ds = 140;
ds_win = 1; if flag_downsample; ds_win = 2; end
    
%% MAIN ALIGNMENT LOOP
for chunk_ctr = start_chunk_ctr:num_chunks
    tic
    ImageStack=zeros(mov_h,mov_w,chunks_lengths_vec(chunk_ctr),'single');
    
    % Decide which channel to use for calculating shifts
    if use_red_channel
        for j=1:chunks_lengths_vec(chunk_ctr)
            ImageStack(:,:,j)=imread(fix_path(chunks_red_filenames{chunk_ctr}{j}));
        end
    else
        for j=1:chunks_lengths_vec(chunk_ctr)
            ImageStack(:,:,j)=imread(fix_path(chunks_green_filenames{chunk_ctr}{j}));
        end
    end

    disp(['Loading Chunk ',num2str(chunk_ctr),' took ',num2str(toc),' seconds']);
    
    %% Apply pre-calculated Rigid shifts
    ImageStack_mc=apply_mc(ImageStack,YY_cell{chunk_ctr},XX_cell{chunk_ctr});
    
    row_patch_start = round(centpatchd_mat2(chunk_ctr,2)-patch_h/2);
    col_patch_start = round(centpatchd_mat2(chunk_ctr,1)-patch_w/2);
    
    %% Calculate and apply Non-Rigid (Demons) alignment
    mc_time=tic;
    [res_str,mc_stack_ds,dsind_cell] = motion_correct_ds_submovie(ImageStack_mc,50,3,max_shift,0.2,1,1,...
        ds_win,-1,[patch_h patch_w],row_patch_start*ones(1,size(ImageStack_mc,3)),col_patch_start*ones(1,size(ImageStack_mc,3)),imsize_extract,threshold_before_ds);
    
    disp(['Calculating and applying motion correction took ',num2str(toc(mc_time)),' seconds']);
    
    % Temporary save
    save([tempfolder,'mc_stack_temp_patch_',num2str(patch_ctr),'_file_',num2str(chunk_ctr)],'mc_stack_ds')
    
    % Store metadata
    res.first_row_translation_vec_cell{chunk_ctr}   = res_str.first_i_vec;
    res.first_col_translation_vec_cell{chunk_ctr}   = res_str.first_j_vec;
    res.first_translation_xcorr_vec_cell{chunk_ctr} = res_str.first_xcorr_vec;
    res.ds_row_translation_vec_cell{chunk_ctr}      = res_str.ds_i_vec;
    res.ds_col_translation_vec_cell{chunk_ctr}      = res_str.ds_j_vec;
    res.ds_translation_xcorr_vec_cell{chunk_ctr}    = res_str.ds_xcorr_vec;
    res.dsind_cell_cell{chunk_ctr}                  = dsind_cell;
    res.row_patch_start_vec(chunk_ctr) = row_patch_start;
    res.col_patch_start_vec(chunk_ctr) = col_patch_start;
    res.all_templates(:,:,chunk_ctr) = res_str.ds_template;
    res.num_frames_file(chunk_ctr)   = size(mc_stack_ds,3);
    
    save([tempfolder,'curres_',num2str(patch_ctr)],'res')
end

load([tempfolder,'curres_',num2str(patch_ctr)],'res');
res.patch_size = [patch_h patch_w];
res.name     = patch_struct.strName;
res.centpatchd_mat2 = centpatchd_mat2;
res.threshold_before_ds = threshold_before_ds;
res.ds_win=ds_win;

save([output_folder,'res_mc_data_',num2str(patch_ctr),'.mat'],'res');

%% SAVING LOOP (RELOADS AND SAVES BOTH CHANNELS)
max_size_file=2.7e9; 
bytes_per_frame = (imsize_extract^2)*4;
bytes_per_file=bytes_per_frame*750;
num_files_per_movie=min(floor(max_size_file/bytes_per_file), floor((2^16-1)/750));

mc_time_template=tic;
[row_translation_templates,col_translation_templates] = mc_rigid(res.all_templates,1,10,20,0.2,1,1);

avg_frame_lim = 500;
avg_movie = []; prev_for_avgs = [];
total_avg_frame_ctr=1;
movie_ctr = 1; savechunk_ctr=1;

disp(' Reloading files, applying global motion correction and saving...')
mc_image_stack_full = [];      
mc_image_stack_full_red = [];      

for chunk_ctr = 1:num_chunks
    disp(['Processing file ',num2str(chunk_ctr),' of ',num2str(num_chunks)])
    
    if ~use_red_channel
        load([tempfolder,'mc_stack_temp_patch_',num2str(patch_ctr),'_file_',num2str(chunk_ctr)],'mc_stack_ds')
        if want_red_channel
            ImageStack=zeros(mov_h,mov_w,chunks_lengths_vec(chunk_ctr),'single');
            for j=1:chunks_lengths_vec(chunk_ctr)
                ImageStack(:,:,j)=imread(fix_path(chunks_red_filenames{chunk_ctr}{j}));
            end
            ImageStack_mc=apply_mc(ImageStack,YY_cell{chunk_ctr},XX_cell{chunk_ctr});
            row_patch_start = round(res.centpatchd_mat2(chunk_ctr,2)-patch_h/2);
            col_patch_start = round(res.centpatchd_mat2(chunk_ctr,1)-patch_w/2);
            mc_stack_ds_red=apply_mc_ds_submovie(ImageStack_mc,res.first_row_translation_vec_cell{chunk_ctr},res.first_col_translation_vec_cell{chunk_ctr},res.threshold_before_ds,res.ds_win,res.patch_size,...
                res.ds_row_translation_vec_cell{chunk_ctr},res.ds_col_translation_vec_cell{chunk_ctr},row_patch_start*ones(1,size(ImageStack_mc,3)),col_patch_start*ones(1,size(ImageStack_mc,3)),imsize_extract2,max_shift);
        end
    else
        if want_red_channel
            load([tempfolder,'mc_stack_temp_patch_',num2str(patch_ctr),'_file_',num2str(chunk_ctr)],'mc_stack_ds')
            mc_stack_ds_red = mc_stack_ds;
        end
        ImageStack=zeros(mov_h,mov_w,chunks_lengths_vec(chunk_ctr),'single');
        for j=1:chunks_lengths_vec(chunk_ctr)
            ImageStack(:,:,j)=imread(fix_path(chunks_green_filenames{chunk_ctr}{j}));
        end
        ImageStack_mc=apply_mc(ImageStack,YY_cell{chunk_ctr},XX_cell{chunk_ctr});
        row_patch_start = round(res.centpatchd_mat2(chunk_ctr,2)-patch_h/2);
        col_patch_start = round(res.centpatchd_mat2(chunk_ctr,1)-patch_w/2);
        mc_stack_ds=apply_mc_ds_submovie(ImageStack_mc,res.first_row_translation_vec_cell{chunk_ctr},res.first_col_translation_vec_cell{chunk_ctr},res.threshold_before_ds,res.ds_win,res.patch_size,...
            res.ds_row_translation_vec_cell{chunk_ctr},res.ds_col_translation_vec_cell{chunk_ctr},row_patch_start*ones(1,size(ImageStack_mc,3)),col_patch_start*ones(1,size(ImageStack_mc,3)),imsize_extract2,max_shift);
    end

    cur_ones_vec = ones(1,res.num_frames_file(chunk_ctr));
    temp_movie = apply_mc(single(mc_stack_ds),row_translation_templates(chunk_ctr)*cur_ones_vec,col_translation_templates(chunk_ctr)*cur_ones_vec);
    mc_image_stack_full = cat(3,mc_image_stack_full,temp_movie);

    if want_red_channel
        temp_movie = apply_mc(single(mc_stack_ds_red),row_translation_templates(chunk_ctr)*cur_ones_vec,col_translation_templates(chunk_ctr)*cur_ones_vec);
        mc_image_stack_full_red = cat(3,mc_image_stack_full_red,temp_movie);
    end

    % Tiff chunking and final save
    if movie_ctr==num_files_per_movie || chunk_ctr==num_chunks
        % ... [Internal averaging logic here] ...
        
        mc_image_stack_full=mc_image_stack_full(max_shift+1:end-max_shift,max_shift+1:end-max_shift,:);
        save_name = [output_folder,'mc_image_stack_full_patch_',num2str(patch_ctr)];
        if chunk_ctr==num_chunks && savechunk_ctr==1; saveastiff(mc_image_stack_full,[save_name,'.tif']);
        else; saveastiff(mc_image_stack_full,[save_name,'_part',num2str(savechunk_ctr),'.tif']); end

        if want_red_channel
            mc_image_stack_full_red=mc_image_stack_full_red(max_shift+1:end-max_shift,max_shift+1:end-max_shift,:);
            save_name_red = [output_folder,'mc_image_stack_red_full_patch_',num2str(patch_ctr)];
            if chunk_ctr==num_chunks && savechunk_ctr==1; saveastiff(mc_image_stack_full_red,[save_name_red,'.tif']);
            else; saveastiff(mc_image_stack_full_red,[save_name_red,'_part',num2str(savechunk_ctr),'.tif']); end
        end
        
        movie_ctr=1; savechunk_ctr=savechunk_ctr+1;
        mc_image_stack_full = []; mc_image_stack_full_red = [];
    else
        movie_ctr=movie_ctr+1;
    end
end

% Finalize
save([output_folder,'res_mc_data_',num2str(patch_ctr),'.mat'],'res');
make_ds5_movie(output_folder,patch_ctr);
disp(['Entire procedure for patch ',num2str(patch_ctr),' took ',num2str(toc(all_patch_time)),' seconds']);

end













