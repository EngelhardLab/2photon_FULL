function process_patch_2Ch(output_folder, patch_file, patch_ctr, want_red, use_red, flag_downsample)
% Default downsample to 0 if not provided
if nargin < 6; flag_downsample = 0; end

% Mapping Channel Logic
if use_red
    chan_prefix = 'red_';
    template_name = 'template_mov.tif'; 
else
    chan_prefix = 'green_';
    template_name = 'template_mov_green.tif';
end

slashind = filesep;
save_name = fullfile(output_folder, ['mc_image_stack_', chan_prefix, 'full_patch_', num2str(patch_ctr), '.tif']);

% 1. Skip if already done
if exist(save_name, 'file')
    disp(['Patch ', num2str(patch_ctr), ' (', chan_prefix, ') already exists. Skipping.']);
    return;
end

% 2. Load Registration Metadata
load(fullfile(output_folder,'chunks_info.mat'));
load(fullfile(output_folder,'demons_disp_cell.mat'));
load(fullfile(output_folder,'final_xy_shifts.mat'));

mov_h = size(disp_cell_summed{1},1);
mov_w = size(disp_cell_summed{1},2);

% 3. Extract ROI Bounds
patch_struct = ReadImageJROI(patch_file);
cur_mask = make_mask_from_roi(patch_struct, [mov_h mov_w]);
[~, cur_patch_coordinates, patch_h, patch_w] = boundingRec(double(cur_mask > 0));

% 4. Downsampling Window
ds_win = 1; 
if flag_downsample; ds_win = 2; end

% 5. Processing Loop
tempfolder = fullfile(output_folder, 'tempsaves', chan_prefix); 
if ~exist(tempfolder,'dir'); mkdir(tempfolder); end

for chunk_ctr = 1:num_chunks
    disp(['Processing chunk ', num2str(chunk_ctr), ' for patch ', num2str(patch_ctr)]);
    
    % Select correct channel files
    filenames = chunks_green_filenames{chunk_ctr};
    if use_red; filenames = chunks_red_filenames{chunk_ctr}; end
    
    % Load and Apply Rigid Shifts
    ImageStack = zeros(mov_h, mov_w, chunks_lengths_vec(chunk_ctr), 'single');
    for j=1:chunks_lengths_vec(chunk_ctr); ImageStack(:,:,j) = imread(filenames{j}); end
    ImageStack_mc = apply_mc(ImageStack, YY_cell{chunk_ctr}, XX_cell{chunk_ctr});
    
    % Local Non-Rigid (Demons) alignment
    [res_str, mc_stack_ds] = motion_correct_ds_submovie(ImageStack_mc, 50, 3, 30, 0.2, 1, 1, ...
        ds_win, -1, [patch_h patch_w], ones(1, size(ImageStack_mc,3)), ones(1, size(ImageStack_mc,3)), ...
        round(1.1*max([patch_h patch_w])), 140);
    
    save(fullfile(tempfolder, ['temp_p', num2str(patch_ctr), '_c', num2str(chunk_ctr)]), 'mc_stack_ds');
end

% 6. Final Concatenation and Save
mc_image_stack_full = [];      
for chunk_ctr = 1:num_chunks
    load(fullfile(tempfolder, ['temp_p', num2str(patch_ctr), '_c', num2str(chunk_ctr)]), 'mc_stack_ds');
    mc_image_stack_full = cat(3, mc_image_stack_full, mc_stack_ds);
end

saveastiff(mc_image_stack_full, save_name);
disp(['Successfully saved: ', save_name]);
end