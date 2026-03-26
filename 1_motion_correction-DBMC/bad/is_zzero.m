function is_zzero(corrected_folder)

slashind = '\';
if isunix
    slashind ='/';
end

% get correct corrected_folder
if ~strcmp(corrected_folder(end),slashind)
    corrected_folder=[corrected_folder,slashind];%folder/   is == savefolder for make_traces.m
end

%getting patches folder just to have a counter 
patches_folder = [corrected_folder,'patches_folder',slashind]; %folder/patches_folder/
numpatches = length(dir([patches_folder,'*.roi'])); %patches counter

k = 0 ;
%getting patches folder just to have a counter 
for i = 1:numpatches
    traces_folders = [corrected_folder,'patch_',num2str(i),'_tracesfolder',slashind] ;%folder/patches_folder/
    %all_exist = 0;
    if exist( traces_folders,'dir')   
        traceslist = dir([traces_folders,'TRACES__*']);

        %get cells traces
        try
            cellfile = dir([traces_folders,traceslist(2).name, slashind,'mc_image_stack_*']);
            tracel_cell=[];
            for j = 1:size(cellfile,1)
                tracel_cell{end+1} = load([cellfile(1).folder, slashind,cellfile(j).name],'trace');
            end 
        catch
            disp(['Cell traces for patch #',num2str(i),' not found, skipping' ]);
        end

        %get bckg traces
        try
            bkgfile = dir([traces_folders,traceslist(1).name, slashind,'mc_image_stack_*']);
            tracel_bkg =[];
            for j = 1:size(bkgfile,1)
                tracel_bkg{end+1} = load([bkgfile(1).folder, slashind,bkgfile(j).name],'trace');
            end
        catch
            disp(['Annulus traces for patch #',num2str(i),' not found, skipping'] );
        end

      
        if size(tracel_cell) == size(tracel_bkg)
            
            for k = 1:size(tracel_bkg,2) %for each ROI
                dffs_cell =[];
                roi_name = ['dff',cellfile(k).name(20:end)];
                for j = 1:size(tracel_bkg{1,k}.trace,2) %for each part of the patch
                    %getting dff for every part
                    
                    dif_z = sum(tracel_cell{1,k}.trace{j} - 0.58 * tracel_bkg{1,k}.trace{j}<0) ;
                    if dif_z < 0
                        disp (['Found zeros in cell ',num2str(k), ' patch #', num2str(i)])
                        k = k +1 ;
                    end

                end
                
            end         

        else 
            disp(['Please check that each ROI in patch #',num2str(i),' has its own traces file.'])

        end
    end

end

if k ~= 0
    disp('Not zeros found !')
end