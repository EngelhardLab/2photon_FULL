%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Ben Engelhard, Princeton University (2019).
%    Modified for Dual Channel Support (2026)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DBMC_2Ch(input_folder,output_folder,have_red_channel,use_red_channel,want_red_channel)

if nargin<3; have_red_channel=0; end
if nargin<4; use_red_channel=0; end
if nargin<5; want_red_channel=0; end

% Handle string inputs from command line/Python
if ischar(have_red_channel); have_red_channel = str2double(have_red_channel); end
if ischar(use_red_channel); use_red_channel = str2double(use_red_channel); end
if ischar(want_red_channel); want_red_channel = str2double(want_red_channel); end

slashind = filesep; % Automatically uses / for Linux and \ for Windows
if ~strcmp(input_folder(end),slashind); input_folder=[input_folder,slashind]; end
if ~strcmp(output_folder(end),slashind); output_folder=[output_folder,slashind]; end

% Configuration based on active channel
if use_red_channel
    disp('>>> Mode: Using RED channel (Ch1) for motion correction')
    patch_prefix = 'red';
    patches_file = fullfile(output_folder, 'patches.zip'); 
    template_check = fullfile(output_folder, 'template_mov_green.tif');
else
    disp('>>> Mode: Using GREEN channel (Ch2) for motion correction')
    patch_prefix = 'green';
    patches_file = fullfile(output_folder, 'patches_g.zip');
    template_check = fullfile(output_folder, 'template_mov.tif');
end

% 1. Translation-only correction
if ~exist(template_check,'file')
    disp('Running translation-only correction on all files.....')
    run_first_rigid_mc_and_get_sharp_templates(input_folder,output_folder,have_red_channel,use_red_channel,slashind);
else
    disp('Translation-only correction already performed, skipping...')
end

% 2. Sharp template generation
if ~exist(fullfile(output_folder,'templates_mov_sharp.tif'),'file')
    disp('Motion correcting sharper templates.....')
    sharptemplate_folder = fullfile(output_folder,'sharptemplates',slashind);
    load(fullfile(output_folder,'chunks_info.mat'),'num_chunks');
    for file_ctr = 1:num_chunks
        curt = load([sharptemplate_folder,'template_',num2str(file_ctr)]);
        templates_mov_uncor(:,:,file_ctr) = curt.cur_template;
    end
    [~,~,~,~,~,templates_mov_corrc] = mc_rigid(templates_mov_uncor,1,10,30,0.2,1,1);
    saveastiff(templates_mov_uncor, fullfile(output_folder,'templates_mov_uncor_sharp.tif'));
    saveastiff(templates_mov_corrc, fullfile(output_folder,'templates_mov_sharp.tif'));
end

% 3. Non-rigid registration (Demons)
demons_filename = fullfile(output_folder,'template_mov_demons.tif');
if ~exist(fullfile(output_folder,'demons_disp_cell.mat'),'file')
    disp('Performing demons registration on the templates.....')
    ImageStack_templates = loadTiffStack_single(fullfile(output_folder,'templates_mov_sharp.tif'));
    disp_cell_summed=drift_correct_demons(ImageStack_templates,demons_filename,20,[20 4]);
    save(fullfile(output_folder,'demons_disp_cell.mat'),'disp_cell_summed')
end

% 4. XML Downsample Check (Median Frame Interval)
disp('Analyzing XML for Median Frame Interval...')
flag_downsample = 0;
try
    [~, subf_name] = fileparts(input_folder(1:end-1));
    xml_path = fullfile(input_folder, [subf_name, '.xml']);
    if exist(xml_path, 'file')
        xml_content = fileread(xml_path);
        reltimesinds = strfind(xml_content, 'relativeTime');
        reltimesvec = zeros(1, 10);
        for relctr = 1:10
            tempstr = xml_content(reltimesinds(relctr+1):reltimesinds(relctr+1)+100);
            dqinds = find(tempstr == '"');
            reltimesvec(relctr) = str2double(tempstr(dqinds(1)+1:dqinds(2)-1));
        end
        if median(diff(reltimesvec)) < 0.04
            flag_downsample = 1;
            disp('High frame rate detected: flag_downsample = 1');
        end
    end
catch
    disp('Warning: Could not parse XML. Defaulting to no downsampling.');
end

% 5. Flexible Patch Handling
if ~exist(patches_file, 'file') && ~use_red_channel && exist(fullfile(output_folder, 'patches.zip'), 'file')
    patches_file = fullfile(output_folder, 'patches.zip');
end

if exist(patches_file,'file')
    patches_extract_dir = fullfile(output_folder, ['patches_folder_', patch_prefix, slashind]);
    if ~exist(patches_extract_dir, 'dir'); mkdir(patches_extract_dir); end
    unzip(patches_file, patches_extract_dir);

    disp(['Starting work on individual ', patch_prefix, ' Patches.....'])
    patcheslist = dir(fullfile(patches_extract_dir, '*.roi'));
    num_patches = length(patcheslist);

    k = 0; % Ensure only one patch per MATLAB instance
    for i=1:num_patches
        patch_file = fullfile(patches_extract_dir, patcheslist(i).name);
        patch_taken_file = fullfile(output_folder, ['Patch_', patch_prefix, '_', num2str(i), ' taken.txt']);
        
        if ~exist(patch_taken_file, 'file') && k == 0 
            f = fopen(patch_taken_file, 'w');
            fprintf(f, 'Processed by DBMC_2Ch on %s', char(datetime));
            fclose(f);
            
            process_patch_2Ch(output_folder, patch_file, i, want_red_channel, use_red_channel, flag_downsample);
            k = 1; 
        end
    end
else
    disp('Phase 1 Complete: Master templates created. No ROIs found to process.');
end
disp(['Finished DBMC_2Ch for ', patch_prefix, ' channel.'])