function whats_missing(corrected_folder)
%corrected_folder   -   session folder where patches/ROIs are   
%                       <ex>: Z:\2Photon_Data\Part-1_Analyzed\m9399\26032025


%This function returns a table which entries are

%   # of ROIs traces files found
%   # of Background ROIs traces " "
%   # of dffs " "

% and a last column called "CHECK !" that tells you to pay attention to
% certain patch. Here, an " !!! " indicates that there are no files
% found for this patch 
% OR 
% that there's something missing (incomplete traces of no dffs)
% also if the patch was not taken at all


%just a variable for the slash
slashind = '\';
if isunix
    slashind ='/';
end

%%
% get correct corrected_folder (where patches are saved)
if ~strcmp(corrected_folder(end),slashind)
    corrected_folder=[corrected_folder,slashind];%folder/   is == savefolder for make_traces.m
end
% <example> : corrected_folder= D:\DBMC_bruker\m9399\23022025_patches
%%

%%
%getting patches folder just to have a counter 
patches_folder = [corrected_folder,'patches_folder',slashind]; % <ex> : D:\DBMC_bruker\m9399\23022025_patches\patches_folder\
patcheslist = dir([patches_folder,'*.roi']);
num_patches = length(patcheslist); %patches counter
%%


types = {'ROIs/cells','BCKG ROIs', 'dffs','CHECK !'};  
types_names = {'cell','annulus','dffs_traces_'};
% 
patchNames = {};
for i = 1:num_patches
    patchNames{end+1} = ['patch_' num2str(i)]; 
end

% find all files w/ 'patch_*'
files = dir(fullfile(corrected_folder, '*patch_*'));
fileNames = {files.name};

%start table
tabla_exist = cell(length(patchNames), length(types));
tabla_exist(:) = {'X'};

for i = 1:num_patches

    for j = 1:length(types)-1
        type = types_names{j};

        if contains(type, 'dff')
            pattern = [corrected_folder,'patch_',num2str(i),'_tracesfolder',slashind,'dffs_traces__patch_',num2str(i),slashind];
            found = ~isempty(dir(pattern));
            if found
                tabla_exist{i, j} = num2str(length(dir([pattern,'*.mat'])));
            end   
        end

        if contains(type, 'cell')
                    pattern = [corrected_folder,'patch_',num2str(i),'_tracesfolder',slashind,'TRACES___patch_',num2str(i),'_cell',slashind];
                    found = ~isempty(dir(pattern));
                    if found
                         tabla_exist{i, j} = num2str(length(dir([pattern,'*.mat'])));
                    end
        end
        if contains(type, 'annulus')
                    pattern = [corrected_folder,'patch_',num2str(i),'_tracesfolder',slashind,'TRACES___patch_',num2str(i),'_annulus',slashind];
                    found = ~isempty(dir(pattern));
                    if found
                         tabla_exist{i, j} = num2str(length(dir([pattern,'*.mat'])));
                    end
        end

       

    end
end


for i = 1:num_patches

    a = [];
    for j = 1 : length(types)-1
        a(j)= tabla_exist{i, j};
    end

    achk = zeros(1,length(a));
    achk(:) = a(1);
    if sum(a ~= achk) 
        tabla_exist{i, length(types)} = '       !!!      ';
    else
        tabla_exist{i, length(types)} = '                ';
    end

    if a(end) == 88
        tabla_exist{i, length(types)} = '    no  dff    '; 
        if a(1) ~= a(2)
            tabla_exist{i, length(types)} = ' no dff / ROIs ';
        end
    end

    achk(:) = 88;
    if a == achk
        tabla_exist{i, length(types)} = '   not taken   '; 
    end
    


end               
         
        

T = cell2table(tabla_exist, 'VariableNames', types, 'RowNames', patchNames);

disp(T)