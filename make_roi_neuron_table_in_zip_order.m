function T = make_roi_neuron_table_mixed(session_folder)
% Handles:
%   ROI_patch_*.zip                -> multi-ROI patches
%   ROI_patch_*_*.roi             -> single-ROI patches
%
% Example:
% T = make_roi_neuron_table_mixed('Z:\2Photon_Data\Pre-processed\m9399\BP_19032025');

    if ~isfolder(session_folder)
        error('Session folder does not exist: %s', session_folder);
    end

    %% -------- Find zip patches --------
    zip_files = dir(fullfile(session_folder, 'ROI_patch_*.zip'));
    zip_patch_nums = [];
    zip_names = {};

    for i = 1:numel(zip_files)
        tok = regexp(zip_files(i).name, '^ROI_patch_(\d+)\.zip$', 'tokens', 'once');
        if ~isempty(tok)
            zip_patch_nums(end+1,1) = str2double(tok{1});
            zip_names{end+1,1} = zip_files(i).name;
        end
    end

    %% -------- Find single ROI patch files --------
    roi_files = dir(fullfile(session_folder, 'ROI_patch_*_*.roi'));
    single_patch_nums = [];
    single_roi_names = {};

    for i = 1:numel(roi_files)
        tok = regexp(roi_files(i).name, '^ROI_patch_(\d+)_(.+)\.roi$', 'tokens', 'once');
        if ~isempty(tok)
            single_patch_nums(end+1,1) = str2double(tok{1});
            % store just the ROI filename part, e.g. 0056-0049.roi
            single_roi_names{end+1,1} = [tok{2}, '.roi'];
        end
    end

    if isempty(zip_patch_nums) && isempty(single_patch_nums)
        error('No ROI patch files found in %s', session_folder);
    end

    %% -------- Combine all patch numbers --------
    all_patches = unique([zip_patch_nums; single_patch_nums]);
    all_patches = sort(all_patches);

    %% -------- Output containers --------
    roi_filename = {};
    patch_number = [];
    patch_cell_number = [];
    patch_cell_label = {};
    patch_cell_compact = {};
    session_neuron_number = [];
    source_type = {};

    neuron_ctr = 1;

    for p = 1:numel(all_patches)
        this_patch = all_patches(p);

        % Case 1: patch stored as zip
        zip_idx = find(zip_patch_nums == this_patch, 1, 'first');
        if ~isempty(zip_idx)
            zip_path = fullfile(session_folder, zip_names{zip_idx});
            roi_names_zip = get_roi_names_in_zip_order(zip_path);

            for j = 1:numel(roi_names_zip)
                roi_filename{end+1,1} = roi_names_zip{j};
                patch_number(end+1,1) = this_patch;
                patch_cell_number(end+1,1) = j;
                patch_cell_label{end+1,1} = sprintf('patch %d cell %d', this_patch, j);
                patch_cell_compact{end+1,1} = sprintf('%d/%d', this_patch, j);
                session_neuron_number(end+1,1) = neuron_ctr;
                source_type{end+1,1} = 'zip';

                neuron_ctr = neuron_ctr + 1;
            end
        end

        % Case 2: patch stored as one single ROI file
        single_idx = find(single_patch_nums == this_patch);

        for j = 1:numel(single_idx)
            % Usually should be just one file per patch
            roi_filename{end+1,1} = single_roi_names{single_idx(j)};
            patch_number(end+1,1) = this_patch;
            patch_cell_number(end+1,1) = j;
            patch_cell_label{end+1,1} = sprintf('patch %d cell %d', this_patch, j);
            patch_cell_compact{end+1,1} = sprintf('%d/%d', this_patch, j);
            session_neuron_number(end+1,1) = neuron_ctr;
            source_type{end+1,1} = 'single_roi';

            neuron_ctr = neuron_ctr + 1;
        end
    end

    %% -------- Make table --------
    T = table(roi_filename, patch_number, patch_cell_number, ...
              patch_cell_label, patch_cell_compact, ...
              session_neuron_number, source_type, ...
              'VariableNames', {'roi_filename', 'patch_number', ...
              'patch_cell_number', 'patch_cell_label', ...
              'patch_cell_compact', 'session_neuron_number', ...
              'source_type'});

    %% -------- Save --------
    writetable(T, fullfile(session_folder, 'roi_neuron_table.csv'));
    save(fullfile(session_folder, 'roi_neuron_table.mat'), 'T');

    disp(T)
end

function roi_names = get_roi_names_in_zip_order(zip_path)
    import java.util.zip.ZipFile

    zf = ZipFile(zip_path);
    cleanupObj = onCleanup(@() zf.close());

    entries = zf.entries();
    roi_names = {};

    while entries.hasMoreElements()
        entry = entries.nextElement();
        entry_name = char(entry.getName());

        if entry.isDirectory()
            continue;
        end

        if length(entry_name) >= 4 && strcmpi(entry_name(end-3:end), '.roi')
            [~, name, ext] = fileparts(entry_name);
            roi_names{end+1,1} = [name ext];
        end
    end
end