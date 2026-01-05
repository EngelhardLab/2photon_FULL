
function get_traces(corrected_folder)
% to get traces (cell & annulus) from a single patch
% adapted from 'get_all_traces.m' to work in parallel with python
% will use function  make_traces(savefolder,tif_files_prefix,roi_files_cell,savesubfolder)
% which needs the following parameters : 
    %savefolder - where cellpatches were saved
    %tif_files_prefix - patch name <ex> : '\mc_image_stack_full_patch_1' remember to add slashs
    %roi_files_cell -  
    %savesubfolder - where to save all traces  

%% after completion please delete all patch_taken_files '____________ROI_patch_*_taken.txt'  
%% if you want to redo a patch please delete it's corresponding '____________ROI_patch_*_taken.txt' file

slashind = '\';
if isunix
    slashind ='/';
end

% get correct corrected_folder
if ~strcmp(corrected_folder(end),slashind)
    corrected_folder=[corrected_folder,slashind];%folder/   is == savefolder for make_traces.m
end
% <example> : corrected_folder = D:\DBMC_bruker\m9399\23022025_patches
%%

%%
%getting patches folder just to have a counter 
patches_folder = [corrected_folder,'patches_folder',slashind]; %folder/patches_folder/
patcheslist = dir([patches_folder,'*.roi']);
num_patches = length(patcheslist); %patches counter

s_time = datetime;%just a time counter to know how long it took to make all traces
k = 0;


for i = 1:num_patches 

    patch_taken_file  = [corrected_folder,'____________ROI_patch_',num2str(i),'_taken.txt']; %to delete after, this is just a flag for the script to know which patch to take now
    
    if ~exist(patch_taken_file,'file') && k == 0 
        f = fopen( patch_taken_file, 'w' );
        fclose(f);

        %%STARTING WITH CELL TRACES
        ROI_file_zipped = [corrected_folder,'ROI_patch_',num2str(i),'.zip']; %name of zip file if exist
        ROI_file_find = dir([corrected_folder,'ROI_patch_',num2str(i),'_*.roi']); %name of singleROI file if exist
        if size(ROI_file_find,1) ~= 0%if a single ROI was found
            ROI_file = [corrected_folder,ROI_file_find.name];
        else
            ROI_file = 'ROI_NonE##';%will assign any name to the variable if it doesn't exist
        end

        if ~exist(ROI_file_zipped,'file') & ~exist(ROI_file,'file')%if none of the files (zip nor single ROI) was found, will skip to next patch
            disp(['NOT FOUND >> ROIs for patch #',num2str(i),'  skipping...'])
        else
            %making folders to save the traces per patch (this will contain
            %traces for both cell and neuropil)
            patch_folder =  [corrected_folder,'patch_',num2str(i),'_tracesfolder',slashind]; %<ex> D:\DBMC_bruker\m9399\23022025_patches\patches_folder\patch8_tracesfolder\
            if ~exist(patch_folder,'dir')%if the folder doesn't exist will create it 
                mkdir(corrected_folder,['patch_',num2str(i),'_tracesfolder']);
            end


            cell_ROI_folder = [patch_folder,'TRACES___patch_',num2str(i),'_cell',slashind];%folder to save only traces of each cell
           
            if ~exist(cell_ROI_folder,'dir')
                mkdir(patch_folder,['TRACES___patch_',num2str(i),'_cell']); %FOLDER FOR CELL TRACES == savesubfolder for make_traces.m
            end

            ROI_folder = [patch_folder,'ROIs_patch_',num2str(i),'_folder',slashind];

            if ~exist(ROI_folder,'dir')
                mkdir(patch_folder,['ROIs_patch_',num2str(i),'_folder']);%folder to save a copy of all '*.roi' files
            end

            if exist(ROI_file_zipped,'file')
                unzip(ROI_file_zipped,ROI_folder); %unzipping if .zip file exists
                n_traces = length(dir([ROI_folder,'*.roi']));
            else
                if exist(ROI_file,'file')
                    copyfile(ROI_file,ROI_folder);% else will copy the single ROI to the 'ROIs_patch_*_folder'
                    n_traces = 1;
                    o = pwd;
                    cd(ROI_folder);
                    movefile(ROI_file_find.name,ROI_file_find.name(13:end));
                    cd(o);
                end
            end

            trace_file = dir([patch_folder,'TRACES___patch_',num2str(i),'_cell',slashind,'mc_image_stack_*']);
            %^^ gets the number of files inside the 'TRACES___patch_*_cell'
            % that match the name 'mc_image_stack_*'
            % if there are not such files, or some traces are missing will continue with>>
            if size(trace_file,1) == 0 | length(trace_file)< n_traces
                disp(['Now starting individual ROIs for patch ', num2str(i), ':'])
                ROIlist_struct = dir([ROI_folder,'*.roi']); % is == roi_files_cell for make_traces.m
                ROIlist = [];
                for k = 1:length(ROIlist_struct)
                    ROIlist{end+1} = [ROI_folder,ROIlist_struct(k).name];%getting the ROI names
                end

                tif_files_prefix = ['mc_image_stack_full_patch_',num2str(i)];%setting the name of the mat file to save the respective trace

                make_traces(corrected_folder,tif_files_prefix,ROIlist,cell_ROI_folder);%uses the function make_traces
            else
                disp(['ROIs traces for ',num2str(i),' already done, skipping...'])
            end

        end
        %%

        %%% STARTING WITH BACKGROUND TRACES
        % is the same code for cells but adapted to analyze the backgrounds now
        ROI_annulus_file_zipped = [corrected_folder,'ROI_patch_',num2str(i),'_annulus.zip']; %zip file
        ROI_annulus_file_find = dir([corrected_folder,'ROI_annulus_patch_',num2str(i),'_*.roi']); %singleROI file
        if size( ROI_annulus_file_find,1) ~= 0
            ROI_annulus_file = [corrected_folder,ROI_annulus_file_find.name];
        else
            ROI_annulus_file = 'ROI_NonE##';
        end

        if ~exist(ROI_annulus_file_zipped ,'file') & ~exist(ROI_annulus_file,'file')
            disp(['NOT FOUND >> background ROIs for patch #',num2str(i),'  skipping...'])
        else
            cell_bckg_ROI_folder = [patch_folder,'TRACES___patch_',num2str(i),'_annulus',slashind];
            if ~exist(cell_bckg_ROI_folder ,'dir')
                mkdir(patch_folder,['TRACES___patch_',num2str(i),'_annulus']); %FOLDER FOR BACKGOUND TRACES
            end

            ROI_annulus_folder = [patch_folder,'ROIs_annulus_patch_',num2str(i),'_folder',slashind];

            if ~exist(ROI_annulus_folder,'dir')
                mkdir(patch_folder,['ROIs_annulus_patch_',num2str(i),'_folder']);
            end

            if exist(ROI_annulus_file_zipped,'file')
                unzip(ROI_annulus_file_zipped,ROI_annulus_folder);
                n_traces = length(dir([ROI_annulus_folder,'*.roi']));
            else
                if exist(ROI_annulus_file,'file')
                    try
                        copyfile(ROI_annulus_file,ROI_annulus_folder);
                        n_traces = 1;
                    catch ME
                        disp('');
                    end
                    o = pwd;
                    cd(ROI_annulus_folder);
                    movefile(ROI_annulus_file_find.name,ROI_annulus_file_find.name(13:end));
                    cd(o);
                end
            end

            trace_file = dir([patch_folder,'TRACES___patch_',num2str(i),'_annulus',slashind,'mc_image_stack_*']);

            if size(trace_file,1) == 0 | length(trace_file)< n_traces

                disp(['Now starting individual background ROIs for patch ', num2str(i), ':'])
                ROIlist_annulus_struct = dir([ROI_annulus_folder,'*.roi']); % is == roi_files_cell for make_traces.m
                ROIlist_annulus = [];
                for k = 1:length(ROIlist_annulus_struct)
                    ROIlist_annulus{end+1} = [ROI_annulus_folder,ROIlist_annulus_struct(k).name];
                end

                tif_files_prefix = ['mc_image_stack_full_patch_',num2str(i)];

                make_traces(corrected_folder,tif_files_prefix,ROIlist_annulus,cell_bckg_ROI_folder);
            else
                disp(['Annulus ROIs traces for ', num2str(i),' already done, skipping...'])
            end
        end
        %%
        k = 1;
    end

end

a2 = datetime;
disp(['[Patch #', num2str(i),'] >>End time : ',char(s_time-a2)]);