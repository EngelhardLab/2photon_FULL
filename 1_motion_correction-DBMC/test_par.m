
patches_file= ['patches.zip'];

% number of matlabs
n_matlabs = 2; % ex
patcheslist = dir([patches_folder, '*.roi']);
num_patches = length(patcheslist);

% dividinng patches
n_patches_per_matlab = floor(num_patches / n_matlabs)
remaining_patches = mod(n_patches, n_matlabs)

for i=1:num_patches 
    patch_taken_file = fullfile(output_folder, ['Patch ', num2str(idx), ' taken.txt']);
    
    if ~exist(patch_taken_file, 'file')


    end
end

% Extract the patch indices for this MATLAB instance
rad_patch = random_indices(start_idx:end_idx);

% Process the patches assigned to this MATLAB instance
disp('Now starting work on assigned patches...');
patches_processed_vec = [];
patches_processed_start_times = {};
patches_processed_end_times = {};

for idx = rad_patch
    patch_file = fullfile(patches_folder, patcheslist(idx).name);
    patch_taken_file = fullfile(output_folder, ['Patch ', num2str(idx), ' taken.txt']);
    
    if ~exist(patch_taken_file, 'file')
        % Mark the patch as taken
        f = fopen(patch_taken_file, 'w');
        fclose(f);
        
        % Process the patch
        patches_processed_vec(end+1) = idx;
        patches_processed_start_times{end+1} = datetime;
        process_patch(input_folder, output_folder, patch_file, idx, have_red_channel, use_red_channel);
        patches_processed_end_times{end+1} = datetime;
    end
end

disp('Finished assigned patches.');

% Log processed patches
for l = 1:length(patches_processed_vec)
    disp(['Patch ', num2str(patches_processed_vec(l)), ...
          ' Start: ', char(patches_processed_start_times{l}), ...
          ' End: ', char(patches_processed_end_times{l})]);
end
