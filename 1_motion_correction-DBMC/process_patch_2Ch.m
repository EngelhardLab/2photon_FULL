function res=process_patch_2Ch(output_folder,patch_file,patch_ctr,want_red_channel,use_red_channel,flag_downsample)
if nargin < 6; flag_downsample = 0; end

% --- CHANNEL PREFIX AND TEMPLATE MAPPING ---
if use_red_channel
    chan_prefix = 'red_';
    % Red channel uses the standard template_mov.tif (Channel 1)
    template_name = 'template_mov.tif'; 
else
    chan_prefix = 'green_';
    % Green channel uses template_mov_green.tif (Channel 2)
    template_name = 'template_mov_green.tif';
end

disp(['Now working on patch ',num2str(patch_ctr), ' (Channel: ', chan_prefix, ')'])
max_shift = 30;
slashind = '\';
if isunix; slashind ='/'; end

% Separate temp folders to prevent file access conflicts during parallel runs
tempfolder = [output_folder,'tempsaves',slashind, chan_prefix]; 
if ~exist(tempfolder,'dir'); mkdir(tempfolder); end

%% 1. Check if run is already done
if ~isempty(dir([output_folder, 'mc_image_stack_', chan_prefix, 'full_patch_', num2str(patch_ctr), '*tif'])) 
    disp(['Patch ', num2str(patch_ctr), ' for ', chan_prefix, ' already processed. Quitting.'])
    res = []; return
end

%% 2. Load metadata
load([output_folder,'chunks_info'],'num_chunks','chunks_lengths_vec','chunks_green_filenames','chunks_red_filenames')
load([output_folder,'demons_disp_cell.mat'],'disp_cell_summed')
load([output_folder,'final_xy_shifts.mat'],'XX_cell','YY_cell')

mov_h=size(disp_cell_summed{1},1);
mov_w=size(disp_cell_summed{1},2);

%% 3. Handle ROI
all_patch_time=tic;
patch_struct = ReadImageJROI(patch_file);
cur_mask=make_mask_from_roi(patch_struct,[mov_h mov_w]);
cur_selection_binary = double(cur_mask>0); 
[~,cur_patch_coordinates,patch_h,patch_w] = boundingRec(cur_selection_binary);

imsize_extract = round(1.1*max([patch_h patch_w]));
imsize_extract2=round(imsize_extract*1.2);

%% 4. Use the CORRECT template for this channel
disp(['Loading template: ', template_name])
mc_tmu = loadTiffStack_single([output_folder, template_name]);

for chunk_ctr = 1:num_chunks
    centpatchd_mat(chunk_ctr,:) = find_center_of_displaced_patch(cur_patch_coordinates,patch_h,patch_w,disp_cell_summed{chunk_ctr});
    row_patch_start_vec(chunk_ctr) = round(centpatchd_mat(chunk_ctr,2)-patch_h/2);
    col_patch_start_vec(chunk_ctr) = round(centpatchd_mat(chunk_ctr,1)-patch_w/2);
end

[rtv_patch,ctv_patch] = mc_rigid_submovie_from_movie(mc_tmu,1,3,max_shift,0.2,1,1,-1,[patch_h patch_w],row_patch_start_vec,col_patch_start_vec,imsize_extract);
centpatchd_mat2=centpatchd_mat-[rtv_patch' ctv_patch'];

%% 5. Main Processing Loop
threshold_before_ds = 140;
ds_win = 1; if flag_downsample; ds_win = 2; end
    
for chunk_ctr = 1:num_chunks
    ImageStack=zeros(mov_h,mov_w,chunks_lengths_vec(chunk_ctr),'single');
    if use_red_channel
        for j=1:chunks_lengths_vec(chunk_ctr); ImageStack(:,:,j)=imread(chunks_red_filenames{chunk_ctr}{j}); end
    else
        for j=1:chunks_lengths_vec(chunk_ctr); ImageStack(:,:,j)=imread(chunks_green_filenames{chunk_ctr}{j}); end
    end
    
    ImageStack_mc=apply_mc(ImageStack,YY_cell{chunk_ctr},XX_cell{chunk_ctr});
    row_patch_start = round(centpatchd_mat2(chunk_ctr,2)-patch_h/2);
    col_patch_start = round(centpatchd_mat2(chunk_ctr,1)-patch_w/2);
    
    [res_str,mc_stack_ds,dsind_cell] = motion_correct_ds_submovie(ImageStack_mc,50,3,max_shift,0.2,1,1,...
        ds_win,-1,[patch_h patch_w],row_patch_start*ones(1,size(ImageStack_mc,3)),col_patch_start*ones(1,size(ImageStack_mc,3)),imsize_extract,threshold_before_ds);
    
    save([tempfolder,'mc_stack_temp_patch_',num2str(patch_ctr),'_file_',num2str(chunk_ctr)],'mc_stack_ds')
    
    res.first_row_translation_vec_cell{chunk_ctr} = res_str.first_i_vec;
    res.first_col_translation_vec_cell{chunk_ctr} = res_str.first_j_vec;
    res.ds_row_translation_vec_cell{chunk_ctr} = res_str.ds_i_vec;
    res.ds_col_translation_vec_cell{chunk_ctr} = res_str.ds_j_vec;
    res.row_patch_start_vec(chunk_ctr) = row_patch_start;
    res.col_patch_start_vec(chunk_ctr) = col_patch_start;
    res.all_templates(:,:,chunk_ctr) = res_str.ds_template;
    res.num_frames_file(chunk_ctr) = size(mc_stack_ds,3);
end

%% 6. Final Save
[row_translation_templates,col_translation_templates] = mc_rigid(res.all_templates,1,10,20,0.2,1,1);
mc_image_stack_full = [];      

for chunk_ctr = 1:num_chunks
    load([tempfolder,'mc_stack_temp_patch_',num2str(patch_ctr),'_file_',num2str(chunk_ctr)],'mc_stack_ds')
    cur_ones_vec = ones(1,res.num_frames_file(chunk_ctr));
    temp_movie = apply_mc(single(mc_stack_ds),row_translation_templates(chunk_ctr)*cur_ones_vec,col_translation_templates(chunk_ctr)*cur_ones_vec);
    mc_image_stack_full = cat(3,mc_image_stack_full,temp_movie);
end

mc_image_stack_full = mc_image_stack_full(max_shift+1:end-max_shift,max_shift+1:end-max_shift,:);
save_name = [output_folder, 'mc_image_stack_', chan_prefix, 'full_patch_', num2str(patch_ctr), '.tif'];
saveastiff(mc_image_stack_full, save_name);

save([output_folder,'res_mc_data_', chan_prefix, num2str(patch_ctr), '.mat'],'res');
disp(['Successfully finished Patch ', num2str(patch_ctr), ' (', chan_prefix, ')']);