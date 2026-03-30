function process_patch_2Ch(output_folder, patch_file, patch_ctr, want_red, use_red, flag_downsample)
    if nargin < 6; flag_downsample = 0; end

    % 1. Load Registration Metadata
    load(fullfile(output_folder,'chunks_info.mat'));
    load(fullfile(output_folder,'demons_disp_cell.mat'));
    load(fullfile(output_folder,'final_xy_shifts.mat'));

    mov_h = size(disp_cell_summed{1},1);
    mov_w = size(disp_cell_summed{1},2);

    % 2. Extract ROI Bounds
    patch_struct = ReadImageJROI(patch_file);
    cur_mask = make_mask_from_roi(patch_struct, [mov_h mov_w]);
    [~, cur_patch_coordinates, patch_h, patch_w] = extract_patch_from_mask(cur_mask);

    % 3. Determine channels to process
    channels_to_process = {'green'};
    if want_red; channels_to_process = {'green', 'red'}; end

    for c = 1:length(channels_to_process)
        current_chan = channels_to_process{c};
        is_red_iter = strcmp(current_chan, 'red');
        chan_prefix = [current_chan, '_'];
        
        save_name = fullfile(output_folder, ['mc_image_stack_', chan_prefix, 'full_patch_', num2str(patch_ctr), '.tif']);

        if exist(save_name, 'file')
            disp(['Patch ', num2str(patch_ctr), ' ', current_chan, ' already exists. Skipping.']);
            continue;
        end

        % Pre-allocate full patch stack
        total_frames = sum(chunks_lengths_vec);
        full_patch_stack = zeros(patch_h, patch_w, total_frames, 'uint16');
        
        frame_idx = 1;
        for chunk_ctr = 1:num_chunks
            disp(['Processing ', current_chan, ' chunk ', num2str(chunk_ctr), ' for patch ', num2str(patch_ctr)]);
            
            % Select correct filenames for this specific channel
            if is_red_iter
                filenames = chunks_red_filenames{chunk_ctr};
            else
                filenames = chunks_green_filenames{chunk_ctr};
            end
            
            % Load and Apply Rigid Shifts
            ImageStack = zeros(mov_h, mov_w, chunks_lengths_vec(chunk_ctr), 'single');
            for j=1:chunks_lengths_vec(chunk_ctr)
                ImageStack(:,:,j) = imread(filenames{j}); 
            end
            ImageStack_mc = apply_mc(ImageStack, YY_cell{chunk_ctr}, XX_cell{chunk_ctr});
            
            % Crop to patch
            patch_stack = ImageStack_mc(cur_patch_coordinates(1):cur_patch_coordinates(2),...
                                       cur_patch_coordinates(3):cur_patch_coordinates(4), :);

            % Apply Non-Rigid (Demons) alignment
            ds_win = 1; if flag_downsample; ds_win = 2; end
            [~, mc_stack_ds] = motion_correct_ds_submovie(patch_stack, 50, 3, 30, 0.2, 1, 1, ...
                ds_win, -1, [patch_h patch_w], ones(1, size(patch_stack,3)), ones(1, size(patch_stack,3)), ...
                round(1.1*max([patch_h patch_w])), 140);
            
            % Insert into full stack
            end_idx = frame_idx + size(mc_stack_ds,3) - 1;
            full_patch_stack(:,:,frame_idx:end_idx) = uint16(mc_stack_ds);
            frame_idx = end_idx + 1;
        end

        % Save the result
        save_astiff(full_patch_stack, save_name);
        disp(['Saved patch ', num2str(patch_ctr), ' channel: ', current_chan]);
    end
end