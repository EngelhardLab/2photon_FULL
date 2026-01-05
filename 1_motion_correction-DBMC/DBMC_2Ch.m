%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    Ben Engelhard, Princeton University (2019).
%    Modified for Dual Channel Support (2026)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DBMC_2Ch.m
%%%
%%% Description: Run motion correction code on a series of tiff files, 
%%% supporting separate patches for Green (Channel 2) and Red (Channel 1).
function DBMC_2Ch(input_folder,output_folder,have_red_channel,use_red_channel,want_red_channel)

if nargin<3
    have_red_channel=0;
end
if nargin<4
    use_red_channel=0;
end
if nargin<5
    want_red_channel=0;
end

% Handle string inputs from command line/Python
if ischar(have_red_channel); have_red_channel = str2double(have_red_channel); end
if ischar(use_red_channel); use_red_channel = str2double(use_red_channel); end
if ischar(want_red_channel); want_red_channel = str2double(want_red_channel); end

% get correct output_folder format
slashind = '\';
if isunix
    slashind ='/';
end
if ~strcmp(input_folder(end),slashind)
    input_folder=[input_folder,slashind];
end
if ~strcmp(output_folder(end),slashind)
    output_folder=[output_folder,slashind];
end

if use_red_channel
    disp('>>> Mode: Using RED channel (Ch1) for motion correction')
    patch_prefix = 'red';
    patches_file = [output_folder, 'patches.zip']; 
else
    disp('>>> Mode: Using GREEN channel (Ch2) for motion correction')
    patch_prefix = 'green';
    patches_file = [output_folder, 'patches_g.zip'];
end

% 1. Translation-only correction
if use_red_channel
    file_to_check = [output_folder,'template_mov_green.tif'];
else
    file_to_check = [output_folder,'template_mov.tif'];    
end

if ~exist(file_to_check,'file')
    disp('Running translation-only correction on all files.....')
    run_first_rigid_mc_and_get_sharp_templates(input_folder,output_folder,have_red_channel,use_red_channel,slashind);
else
    disp('Translation-only correction already performed, skipping...')
end

% 2. Sharp template generation
try
    if ~exist([output_folder,'templates_mov_sharp.tif'],'file')
        disp('Motion correcting sharper templates.....')
        sharptemplate_folder = [output_folder,'sharptemplates',slashind];
        load([output_folder,'chunks_info'],'num_chunks');
        for file_ctr = 1:num_chunks
            curt = load([sharptemplate_folder,'template_',num2str(file_ctr)]);
            templates_mov_uncor(:,:,file_ctr) = curt.cur_template;
        end
        
        [~,~,~,~,~,templates_mov_corrc] = mc_rigid...
            (templates_mov_uncor,1,10,30,0.2,1,1);
        saveastiff(templates_mov_uncor,[output_folder,'templates_mov_uncor_sharp.tif']);
        saveastiff(templates_mov_corrc,[output_folder,'templates_mov_sharp.tif']);
    else
        disp('Sharp template movie exists, skipping sharp template generation...')
    end
catch ME
    disp(['Error in sharp template phase: ', ME.message])
end

% 3. Non-rigid registration (Demons)
demons_filename = [output_folder,'template_mov_demons.tif'];
if ~exist([output_folder,'demons_disp_cell.mat'],'file')
    disp('Performing demons registration on the templates.....')
    ImageStack_templates = loadTiffStack_single([output_folder,'templates_mov_sharp.tif']);
    disp_cell_summed=drift_correct_demons(ImageStack_templates,demons_filename,20,[20 4]);
    save([output_folder,'demons_disp_cell.mat'],'disp_cell_summed')
else
    disp('Demons registration exists, skipping.....')    
end

% 4. Patch Handling Logic (Target correct ZIP and Folder)
if ~exist(patches_file,'file')
    if ~use_red_channel && exist([output_folder, 'patches.zip'], 'file')
        patches_file = [output_folder, 'patches.zip'];
    else
        error(['CRITICAL: Patch file not found: ', patches_file]);
    end
end

patches_extract_dir = [output_folder, 'patches_folder_', patch_prefix, slashind];
if ~exist(patches_extract_dir, 'dir')
    mkdir(patches_extract_dir);
end

disp(['Unzipping ', patch_prefix, ' patches...']);
unzip(patches_file, patches_extract_dir);

% 5. Process individual patches
disp(['Starting work on individual ', patch_prefix, ' Patches.....'])
patcheslist = dir([patches_extract_dir, '*.roi']);
num_patches = length(patcheslist);

k = 0; % Flag to process only ONE patch per MATLAB instance for Python parallelization

for i=1:num_patches
    patch_file = [patches_extract_dir, patcheslist(i).name];
    
    % Use channel-specific "taken" marker
    patch_taken_file = [output_folder, 'Patch_', patch_prefix, '_', num2str(i), ' taken.txt'];
    
    if ~exist(patch_taken_file, 'file') && k == 0 
        % Mark as taken
        f = fopen(patch_taken_file, 'w');
        fprintf(f, 'Processed by DBMC_2Ch on %s', char(datetime));
        fclose(f);
        
        % CALL THE NEW 2-CHANNEL PATCH PROCESSOR
        process_patch_2Ch(output_folder, patch_file, i, want_red_channel, use_red_channel);
        
        k = 1; % Finish this instance
    end
end

disp(['Finished processing for this ', patch_prefix, ' channel instance.'])