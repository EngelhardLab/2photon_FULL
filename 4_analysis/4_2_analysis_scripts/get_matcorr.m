function get_matcorrs(input_folder, corrected_folder)
%03/08
%%
% input_folder -- folder where the sync folder and behaviour files are in
                    %REMEMBER TO COPY THE BEHAVIOUR FILE TO THE FOLDER WHERE THE SYNC FOLDER IS
% corrected_folder -- Patches folder where the dffs file is saved ('000_all_dffs_session.mat')

%example input :
%    get_matcorrs('D:\DBMC_bruker\m9399\input9399\24022025\bhv_n_sync','D:\DBMC_bruker\m9399\24022025')
% 

%% correcting folder paths (adding the slash chars at the end)

%%folder with scripts used to read the behaviour data
%just in case                       %% CHANGE TO THE PATH ON YOUR COMPUTER !!
try
    addpath(genpath('C:\Users\EngelhardBlab\OneDrive - Technion\Lab\software\VirRMen_bezos_sep17')) %contains scripts that help read the bhv data
catch
    disp('Couldnt find path to VirRMen_bezos_sep17.Assuming it was added beforehand// Skipping...                     (This might cause an error if the path wasnt add before)')
end

slashind = '\';
if isunix
    slashind ='/';
end

if ~strcmp(input_folder(end),slashind)
    input_folder=[input_folder,slashind];  
end

if ~strcmp(corrected_folder(end),slashind)
    corrected_folder=[corrected_folder,slashind];  
end



%% loading files 
%load('D:\DBMC_bruker\m9399\input9399\23022025\syncdata\frames_behav_time_vec.mat')
try
    load([input_folder,'syncdata\frames_behav_time_vec.mat']) %sync file
catch
    error('Please make sure the sync folder is in the input folder.');
end

%behavior data
try
    file_b = dir([input_folder,'PoissonBlocksShapingC_Cohort5','*.mat']);
catch
    error('Please make sure the behavior file is in the input folder.');
end

mouse = file_b.name(52:55); %mouse number 
date_sess = file_b.name(59:end-4);
date_sess = [date_sess(7:end),date_sess(5:6),date_sess(1:4)];
%date_sess = [input_folder(32:33),input_folder(34:35),input_folder(36:39)];
load([input_folder, file_b.name]);

%loading task name
if contains(log.animal.experiment,'impHint')
    type_of_maze = 'T-Maze';
else
    type_of_maze = 'Linear Track';
end



% loading all dffs from session
load([corrected_folder,'000_all_dffs_session.mat']);



%%

%getting patches folder just to have a counter 
patches_folder = [corrected_folder,'patches_folder',slashind]; %folder/patches_folder/
num_patchs = length(dir([patches_folder,'*.roi'])); %patches counter
labels = {};


%%
fig4 = figure; 

% Plot for dffs
ax1 = subplot(2,2,1); 
%hold(ax1, "on");
hold on;
neuron_ctr = 0;
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
legend(labels);
title('dffs all cells');
%hold(ax1,"off");
hold off;



%% Getting the correlation matrices and hierarchical order (leafOrder)

act =gpuArray.zeros(length(A),length(A{1}));

for i =1:neuron_ctr
    act(i,:)=A{i}; %creo que hay una mejor forma de ordenar lol
end

matcorr = corr(act', 'rows','complete'); %to ignore NaNs
mat_corr = gather(matcorr); 


%reordering by hierarchy (from Liza's code)
% Convert correlation into a distance metric
distMatrix = 1 - mat_corr; 
% Convert matrix to vector form for linkage function
distVector = squareform(distMatrix);
% Perform hierarchical clustering using 'average' linkage
Z = linkage(distVector, 'average'); 

% Compute optimal leaf order
leafOrder = optimalleaforder(Z, distVector);
% Reorder correlation matrix
sortedCorrMatrix = mat_corr(leafOrder, leafOrder);
save([corrected_folder,'correlation_matrix'],'matcorr','sortedCorrMatrix','leafOrder','date_sess');
originalNeuronIndices = (1:size(A, 2))'; % Original indices (1 to N)

% Reorder original indices according to hierarchical clustering
sortedNeuronIndices = originalNeuronIndices(leafOrder);
%sortedNeuronIndices = labels(leafOrder);

% Number of neurons (columns in dff_traces)
numNeurons = size(A, 2);

% Generate default neuron labels: 'Neuron 1', 'Neuron 2', ..., 'Neuron N'
neuronNames = strcat("Neuron ", string(1:numNeurons));

% Reorder neuron names based on hierarchical clustering
sortedNeuronNames = neuronNames(sortedNeuronIndices);

% Convert sorted correlation matrix into a labeled table
sortedCorrTable = array2table(sortedCorrMatrix, 'VariableNames', sortedNeuronNames, 'RowNames', sortedNeuronNames);

% Plot heatmap with reordered neurons
subplot(2,2,2); 
imagesc(sortedCorrMatrix);
colorbar;
colormap(jet); % Use jet colormap
caxis([0 1]); % Set color limits for correlation values
axis square;
title('Hierarchical Clustering of Neurons');
xlabel('Neuron Index');
ylabel('Neuron Index');

% Change tick labels to original neuron indices
xticks(1:length(sortedNeuronIndices));
yticks(1:length(sortedNeuronIndices));
xticklabels(string(sortedNeuronIndices)); % Label with original neuron numbers
yticklabels(string(sortedNeuronIndices));
xtickangle(90); % Rotate x-axis labels for better readability
%% getting 0 to 300
for trialctr = 1:length(log.block.trial)
    [~,minind00] = min(abs(log.block.trial(trialctr).position(:,2)-0));
    [~,minind300] = min(abs(log.block.trial(trialctr).position(:,2)-300));
    times_00_vec(trialctr) = log.block.trial(trialctr).time(minind00)+log.block.trial(trialctr).start;
    times_300_vec(trialctr) = log.block.trial(trialctr).time(minind300)+log.block.trial(trialctr).start;
end

all_dffs_pos_0_to_300 = [];


for trialctr = 1:length(log.block.trial)
    [~,minind0_start] = min(abs(frames_behav_time_vec-times_00_vec(trialctr)));
    [~,minind0_end] = min(abs(frames_behav_time_vec-times_300_vec(trialctr)));
    curdffs = [];
    for cellctr = 1:length(A)
        curdffs(cellctr,:) = A{cellctr}(round(minind0_start/2):round(minind0_end/2));
    end
    all_dffs_pos_0_to_300 = [all_dffs_pos_0_to_300 curdffs];
end


%% Plotting correlation matrix for rewards only (0 to 208 distance units on maze)

for trialctr = 1:length(log.block.trial)
    [~,minind0] = min(abs(log.block.trial(trialctr).position(:,2)-0));
    [~,minind280] = min(abs(log.block.trial(trialctr).position(:,2)-280));
    times_0_vec(trialctr) = log.block.trial(trialctr).time(minind0)+log.block.trial(trialctr).start;
    times_280_vec(trialctr) = log.block.trial(trialctr).time(minind280)+log.block.trial(trialctr).start;
end

all_dffs_pos_0_to_280 = [];


for trialctr = 1:length(log.block.trial)
    [~,minind_start] = min(abs(frames_behav_time_vec-times_0_vec(trialctr)));
    [~,minind_end] = min(abs(frames_behav_time_vec-times_280_vec(trialctr)));
    curdffs = [];
    for cellctr = 1:length(A)
        curdffs(cellctr,:) = A{cellctr}(round(minind_start/2):round(minind_end/2));
    end
    all_dffs_pos_0_to_280 = [all_dffs_pos_0_to_280 curdffs];
end

    mat_corr_0280 = corr(all_dffs_pos_0_to_280', 'rows','complete'); 
    distMatrix = 1 - mat_corr_0280; 
    
    % Convert matrix to vector form for linkage function
    %distVector = squareform(distMatrix);
    % Perform hierarchical clustering using 'average' linkage
    %Z = linkage(distVector, 'average'); 

    %leafOrder = optimalleaforder(Z, distVector);
    sortedCorrMatrix_0280 = mat_corr_0280(leafOrder, leafOrder);
    save([corrected_folder,'reordered_matrx'],'mat_corr_0280','matcorr','type_of_maze','date_sess','all_dffs_pos_0_to_280','all_dffs_pos_0_to_300');
    originalNeuronIndices = (1:size(A, 2))'; % Original indices (1 to N)

    % Reorder original indices according to hierarchical clustering
    sortedNeuronIndices = originalNeuronIndices(leafOrder);

    % Plot heatmap with reordered neurons
    subplot(2,2,4);
    imagesc(sortedCorrMatrix_0280);
    colorbar;
    colormap(jet); % Use jet colormap
    caxis([0 1]); % Set color limits for correlation values
    axis square;
    title('Hierarchical Clustering (w/o Reward times)');
    xlabel('Neurons');
    ylabel('Neurons');

    % Change tick labels to original neuron indices
    xticks(1:length(sortedNeuronIndices));
    yticks(1:length(sortedNeuronIndices));
    xticklabels(string(sortedNeuronIndices)); % Label with original neuron numbers
    yticklabels(string(sortedNeuronIndices));
    xtickangle(90); % Rotate x-axis labels for better readability

    %uncomment to remove ticks/neuron labels
    %xticks([]);
    %yticks([]);



%% Plotting the HIGHLY correlated neurons (if any) (also from Liza's code)

% Define correlation threshold
threshold = 0.8;

% Find neuron pairs with correlation > thresholld (excluding self-correlation)
[rowIdx, colIdx] = find(triu(mat_corr,1) > threshold);

% Extract unique neuron indices involved in high correlations
highCorrNeurons = unique([rowIdx; colIdx]);

% Create figure
subplot(2,2,3); 
hold on;
%18/05
% Assign colors for better visualization
cmap = lines(length(highCorrNeurons));

% Plot each neuron's dff_traces
for i = 1:length(highCorrNeurons)
    neuronIdx = highCorrNeurons(i);
    plot(A{neuronIdx}, 'Color', cmap(i,:), 'LineWidth', 1.5);
end
% Add legend
legend(strcat("Neuron ", string(highCorrNeurons)), 'Location', 'bestoutside');

% Label axes
xlabel('Time (Frames)');
ylabel('dF/F');
title('Highly Correlated Neurons (r > 0.8)');
%grid on;
sgtitle([type_of_maze,' - ',date_sess]);

saveas(fig4,[corrected_folder,'matrices_graph']);
hold off;
end
%%
%figure;imagesc(sortedCorrMatrix-sortedCorrMatrix_0280);shg

%%


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



