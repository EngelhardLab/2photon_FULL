function see_dffs(corrected_folder)

% corrected_folder -- Patches folder where the dffs file is saved ('000_all_dffs_session.mat')

slashind = '\';
if isunix
    slashind ='/';
end


if ~strcmp(corrected_folder(end),slashind)
    corrected_folder=[corrected_folder,slashind];  
end


% loading all dffs from session
load([corrected_folder,'000_all_dffs_session.mat']);



%%

%getting patches folder just to have a counter 
patches_folder = [corrected_folder,'patches_folder',slashind]; %folder/patches_folder/
num_patchs = length(dir([patches_folder,'*.roi'])); %patches counter
labels = {};


%%
figure; 

neuron_ctr = 0;
hold on;
for i = 1: num_patchs
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
            ax1 = graph_trace(dff_cell_all_parts);
            labels{end+1} =['neuron ', num2str(i),num2str(k),'/',num2str(neuron_ctr)];
            disp('')
        end

    end
end
hold off
legend(labels)
title('dffs');

end

%%
function ax = graph_trace(dff,samp_freq)

if nargin<2
    samp_freq = 15;
end

ts = (0:length(dff)-1)/samp_freq;


ax = plot(ts,dff); %shg;pause;

xlabel('(s)');
ylabel('dF/f');
xlim([ts(1) ts(end)]);
end
%%
