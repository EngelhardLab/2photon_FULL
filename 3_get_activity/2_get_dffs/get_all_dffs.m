function get_all_dffs(corrected_folder)
%FUNCTION FILES NEEDED> get_dff.m  ,  running_percentile.m


slashind = '\';
if isunix
    slashind ='/';
end

% get corrected_folder (where patches are)
if ~strcmp(corrected_folder(end),slashind)
    corrected_folder=[corrected_folder,slashind];%folder/   is == savefolder for make_traces.m
end

%getting patches folder just to have a counter 
patches_folder = [corrected_folder,'patches_folder',slashind]; %folder/patches_folder/
numpatches = length(dir([patches_folder,'*.roi'])); %patches counter


for i = 1:numpatches
    traces_folders = [corrected_folder,'patch_',num2str(i),'_tracesfolder',slashind] ;%folder/patch_*_tracesfolder/
    %all_exist = 0;
    if exist( traces_folders,'dir')   %if there's a folder for the patch traces
        traceslist = dir([traces_folders,'TRACES__*']);

        
        %get cells traces
        try
            cellfile = dir([traces_folders,traceslist(2).name, slashind,'mc_image_stack_*']); %calls correspondent .mat file for the cell
            tracel_cell=[];
            for j = 1:size(cellfile,1)
                tracel_cell{end+1} = load([cellfile(1).folder, slashind,cellfile(j).name],'trace');
                try
                    ll = length(tracel_cell{end}.trace);
                catch
                    disp('')

                end 
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
                try
                    ll = length(tracel_bkg{end}.trace);
                catch
                    disp('')

                end 
            end
        catch
            disp(['Annulus traces for patch #',num2str(i),' not found, skipping'] );
        end


        ROI_folder = [traces_folders,'ROIs_patch_',num2str(i),'_folder',slashind];    %ROIs_patch_*_folder
        n_traces = length(dir([ROI_folder,'*.roi']));
              
        if size(tracel_cell) == size(tracel_bkg) %equal number of ROIs traces

            savefolder = [traces_folders,'dffs_traces__patch_',num2str(i),slashind];

            if ~exist(savefolder,'dir')
                mkdir(traces_folders,['dffs_traces__patch_',num2str(i),slashind]);
            end

            trace_file = dir([savefolder,'dff_patch_*']);

            if size(trace_file,1) == 0 | length(trace_file)< n_traces

                for k = 1:size(tracel_bkg,2) %for each ROI cell
                    disp(['Now running dff for traces of patch #',num2str(i), ' cell #', num2str(k)]);
                    dffs_cell =[];
                    roi_name = ['dff',cellfile(k).name(20:end)];

                    if exist([savefolder,roi_name])
                        disp(['>>> (((Patch #',num2str(i),' cell #', num2str(k),' already done, skipping)))'])
                    else                   
                        concatenate = 0 ;
                        for l = 1:length(length(tracel_cell{1,k}.trace))
                            is_short = length(tracel_cell{1,k}.trace{l});
                            if is_short < 60*15
                                    concatenate = 1;
                            end
                        end
                        if concatenate
                                %correcting cell trace
                                tracell_trace_end = cat(1,tracel_cell{1,k}.trace{end-1},tracel_cell{1,k}.trace{end});
                                tracel_cell{1,k}.trace{end-1} = tracell_trace_end;
                                tracel_cell{1,k}.trace(end) = [];
                                %correcting bckg trace
                                tracellbckg_trace_end = cat(1,tracel_bkg{1,k}.trace{end-1},tracel_bkg{1,k}.trace{end});
                                tracel_bkg{1,k}.trace{end-1} = tracellbckg_trace_end;
                                tracel_bkg{1,k}.trace(end) = [];
                        end
                    


                    
                    try                    

                    for j = 1:size(tracel_bkg{1,k}.trace,2) %for each part of the patch
                        
                        if sum(~isnan(tracel_cell{1,k}.trace{j}))
                            %getting dff for every part
                            dff = get_dff(tracel_cell{1,k}.trace{j} - 0.58 * tracel_bkg{1,k}.trace{j},15,60,1);                            
                        else
                            %in case trace part is full of NaNs
                            dff = zeros(1,length(tracel_cell{1,k}.trace{j}),"gpuArray"); 
                            dff(:) = NaN;                            
                        end

                        dffs_cell{end+1} = dff;
                    end
                    save([savefolder,roi_name],'dffs_cell')
                    catch
                        disp(['Could not process patch #', num2str(i),' part ', num2str(j),', skipping ...' ]);
                    end

              end
                
    
           end 
           else
                disp(['ROIs traces for ' , num2str(i), ' already done, skipping...']);
       
           end 

        else 
            disp(['Please check that each ROI in patch #',num2str(i),' has its own traces file.'])

        end
    end
end    



%generating a file that saves all dffs in one single file
disp('>>>>>>> Now generating a single file for dffs from all ROIs <<<<<<<')

neuron_ctr = 0;
labels = [];
A = [];

for i = 1: numpatches
    dff_folder = [corrected_folder,'patch_',num2str(i),'_tracesfolder',slashind,'dffs_traces__patch_',num2str(i),slashind];
    n_traces_folder = dir([corrected_folder,'patch_',num2str(i),'_tracesfolder',slashind,'ROIs_patch_',num2str(i),'_folder',slashind,'*.roi']);
    n_traces = length(n_traces_folder);

    if ~exist(dff_folder,'dir')| length(dff_folder)< n_traces
        disp(['Not found or missing files>> dF/F for patch #',num2str(i)]);
    else
        dff_files = dir([dff_folder,'dff_patch_*']);
        for k = 1:n_traces
            neuron_ctr = neuron_ctr +1;
            dff_cell = load([dff_folder, dff_files(k).name],'dffs_cell');
            dff_cell_all_parts = [dff_cell.dffs_cell{:}];
            A{end+1} = dff_cell_all_parts; 
            labels{end+1}=['cell',num2str(i*10+k),'/',num2str(neuron_ctr)];
            disp('')
        end

    end
end
save([corrected_folder,'000_all_dffs_session'],'A','labels');

disp('>>>>>>> Finished !')