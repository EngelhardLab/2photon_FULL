function graph_N_corrmat(corrected_folder)

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
num_patchs = length(dir([patches_folder,'*.roi'])); %patches counter
labels = [];
A = [];
figure;
hold on
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
            A{end+1} = dff_cell_all_parts; 
            graph_trace(dff_cell_all_parts);
            labels{end+1}=['cell',num2str(i*10+k),'/',num2str(neuron_ctr)];
            disp('')
        end

    end
end

save([corrected_folder,'000_all_dffs_session'],'A','labels');

legend(labels);
hold off
disp('')


%%
act =gpuArray.zeros(length(A),length(A{1}));

for i =1:neuron_ctr
    act(i,:)=A{i};
end

matcorr = corr(act');
mat_corr = gather(matcorr);
% figure; imagesc(mat_corr);colorbar;colormap(jet);

%reordering by means
MeanCorrMatPerm = mean(mat_corr);
[sortedCorr, indPerm] = sort(MeanCorrMatPerm, 'descend');
sortedData = mat_corr(indPerm, indPerm);
sortedNames = labels(indPerm);
figure; imagesc(sortedData);
set(gca, 'XTick', 1:length(sortedNames), 'XTickLabel', sortedNames);
set(gca, 'YTick', 1:length(sortedNames), 'YTickLabel', sortedNames);
caxis([0 1]);
colorbar;
colormap(jet);

%%
%reordering by hierarchy

% Convert correlation into a distance metric
distMatrix = 1 - mat_corr; 
% Convert matrix to vector form for linkage function
distVector = squareform(distMatrix);
% Perform hierarchical clustering using 'average' linkage
Z = linkage(distVector, 'average'); 

% Plot dendrogram
figure;
dendrogram(Z);
title('Hierarchical Clustering of Neuronal Activity');
xlabel('Neuron Index');
ylabel('Dissimilarity (1 - Correlation)');

% Compute optimal leaf order
leafOrder = optimalleaforder(Z, distVector);
% Reorder correlation matrix
sortedCorrMatrix = mat_corr(leafOrder, leafOrder);
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
figure;

% Plot heatmap with reordered neurons
imagesc(sortedCorrMatrix);
colorbar;
colormap(jet); % Use jet colormap
caxis([0 1]); % Set color limits for correlation values
axis square;
title('Hierarchical Clustering of Neurons (Correlation Matrix) during T-maze Task');
xlabel('Neuron Index (Clustered)');
ylabel('Neuron Index (Clustered)');

% Change tick labels to original neuron indices
xticks(1:length(sortedNeuronIndices));
yticks(1:length(sortedNeuronIndices));
xticklabels(string(sortedNeuronIndices)); % Label with original neuron numbers
yticklabels(string(sortedNeuronIndices));
xtickangle(90); % Rotate x-axis labels for better readability



%%
% PLOT HIGHLY correlated

% Define correlation threshold
threshold = 0.8;

% Find neuron pairs with correlation > thresholld (excluding self-correlation)
[rowIdx, colIdx] = find(triu(mat_corr,1) > threshold);

% Extract unique neuron indices involved in high correlations
highCorrNeurons = unique([rowIdx; colIdx]);

% Create figure
figure; hold on;

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
grid on;
hold off;



end
%%


%%
function graph_trace(dff,samp_freq)

if nargin<2
    samp_freq = 15;
end

ts = (0:length(dff)-1)/samp_freq;


plot(ts,dff);

xlabel('(s)');
ylabel('dF/f');
xlim([ts(1) ts(end)]);
end
%%