function check_raw(folder1, folder2)

    if ~isfolder(folder1)
        error(['folder <<',folder1, '>> doesnt exist ']); % to check from
    end
    if ~isfolder(folder2)
        error(['folder <<',folder2, '>> doesnt exist ']); %converted folder
    end
    
    % subfolder
    subfolders1 = dir(folder1);
    subfolders2 = dir(folder2);
    
    % ignore "." et ".."
    subfolders1 = subfolders1([subfolders1.isdir] & ~ismember({subfolders1.name}, {'.', '..'}));
    subfolders2 = subfolders2([subfolders2.isdir] & ~ismember({subfolders2.name}, {'.', '..'}));
    
    % list folder 1
    folder_names1 = {subfolders1.name};
    folder_names2 = {subfolders2.name};

    matched_folders = table('Size', [0, 4], 'VariableTypes', {'string', 'string', 'string','string'}, ...
                            'VariableNames', {'RAW', 'Converted', 'Path','test_conversion_output'});
    
    % find same name folders
    for i = 1:length(folder_names1)
        folder_name1 = folder_names1{i};
        folder_name2 = folder_names2{i};
        
        idx = find(strcmp(folder_name1, {subfolders2.name}));
        
        if ~isempty(idx)
            path_folder2 = fullfile(folder2, subfolders2(idx).name);  
            outt = 'No T-series found';
            try
                [~,~,outt] = test_2p_file_conversion(path_folder2);
            catch
                disp('No T-series found');
            end
            matched_folders = [matched_folders; {folder_name1, subfolders2(idx).name, path_folder2,outt}];
        end
    end
    
    if isempty(matched_folders)
        disp('no folders found');
    else
        disp('folders found');
        disp(matched_folders);
    end
end

