function reorder_byleaforder(patches_folder, where_leafOrder_file)

%just a variable for the slash
slashind = '\';
if isunix
    slashind ='/';
end

if nargin < 2 
    error('>>>>>>>>>>>>>>>>> Please introduce the leafOrder file path to reorder neurons!') ;
else
    where_leafOrder_file = [where_leafOrder_file,slashind,'correlation_matrix.mat'] ;
    %this file contains the following variables>>> {'sortedCorrMatrix_0280','type_of_maze','date_sess'}
    load(where_leafOrder_file,'sortedCorrMatrix','leafOrder','date_sess');
    leafOrder_BASE = leafOrder;
    base_date = date_sess;
    base_mtrx = sortedCorrMatrix;
    
end

%load('D:\DBMC_bruker\m9399\23022025_patches\000_all_dffs_session.mat')
load([patches_folder,slashind,'000_all_dffs_session.mat']);
%load([patches_folder,slashind,'correlation_matrix.mat']);
load([patches_folder,slashind,'reordered_matrx.mat'],'mat_corr_0280','matcorr','date_sess','all_dffs_pos_0_to_300','type_of_maze');

%% 
%% reading vector
txt_vector = [patches_folder,slashind,'neuronvector',date_sess,'_',base_date,'.txt'];
try     
    txt_vector= readlines(txt_vector,"EmptyLineRule","skip");
    
catch
    error(['>>>>>>>> Could not find neuronvector',date_sess,'.txt file.']);
end


%to_del = [];
txt_vector = txt_vector';
reorder_by= [];
for i = 1:length(txt_vector)
    reorder_by(i) =  str2num(txt_vector{1,i}) ;    
end
%%

%%

corrmat_w_ghosts = padarray(mat_corr_0280,1,-1,'post') ; 
corrmat_w_ghosts = corrmat_w_ghosts' ;
corrmat_w_ghosts = padarray(corrmat_w_ghosts,1,-1,'post');
corrmat_w_ghosts(end,end) = 1;
ghost_idx = length(corrmat_w_ghosts);

for i = 1:length(reorder_by)
    if reorder_by(i) == 100
        reorder_by(i) = ghost_idx;
        %to_del = [to_del, i]; 
    end
end

while length(reorder_by) ~= length(leafOrder_BASE)
    leafOrder_BASE(end+1) = length(leafOrder_BASE) + 1 ;
end

    %mat_corr = sortedCorrMatrix_0280(reorder_by,reorder_by);
    mat_corr = corrmat_w_ghosts(reorder_by,reorder_by);
    sortedCorrMatrix = mat_corr(leafOrder_BASE, leafOrder_BASE);

   
    originalNeuronIndices = (1:size(all_dffs_pos_0_to_300, 2))';

    % Reorder original indices according to hierarchical clustering
    sortedNeuronIndices = originalNeuronIndices(leafOrder_BASE);

fig2 = figure; 

%%
    ax1 = subplot(1,3,1); 
    % Plot heatmap with reordered neurons
    imagesc(sortedCorrMatrix);
    colorbar;
    colormap(jet); % Use jet colormap
    caxis([0 1]); % Set color limits for correlation values
    axis square;
    title([type_of_maze , 'Hierarchical base-Clustering (w/o Reward times)']);
    xlabel('Neurons');
    ylabel('Neurons');

    % Change tick labels to original neuron indices
    xticks(1:length(sortedNeuronIndices));
    yticks(1:length(sortedNeuronIndices));
    xticklabels(string(sortedNeuronIndices)); % Label with original neuron numbers
    yticklabels(string(sortedNeuronIndices));
    xtickangle(90); % Rotate x-axis labels for better readability

    %uncomment to remove ticks/neuron labels and comment the previous 5 lines
    %xticks([]);
    %yticks([]);


    %%
corrmat_w_ghosts = padarray(matcorr,1,-1,'post') ; 
corrmat_w_ghosts = corrmat_w_ghosts' ;
corrmat_w_ghosts = padarray(corrmat_w_ghosts,1,-1,'post');
corrmat_w_ghosts(end,end) = 1;

mat_corr = corrmat_w_ghosts(reorder_by,reorder_by);
sortedCorrMatrix = mat_corr(leafOrder_BASE, leafOrder_BASE);

    ax2 = subplot(1,3,2); 

    % Plot heatmap with reordered neurons
    imagesc(sortedCorrMatrix);
    colorbar;
    colormap(jet); % Use jet colormap
    caxis([0 1]); % Set color limits for correlation values
    axis square;
    title('Hierarchical base-Clustering ');
    xlabel('Neurons');
    ylabel('Neurons');

    % Change tick labels to original neuron indices
    xticks(1:length(sortedNeuronIndices));
    yticks(1:length(sortedNeuronIndices));
    xticklabels(string(sortedNeuronIndices)); % Label with original neuron numbers
    yticklabels(string(sortedNeuronIndices));
    xtickangle(90); % Rotate x-axis labels for better readability

    %uncomment to remove ticks/neuron labels and comment the previous 5 lines
    %xticks([]);
    %yticks([]);



%%

ax2 = subplot(1,3,3); 

    % Plot heatmap with reordered neurons
    imagesc(base_mtrx); %sortedCorrMatrix contains the WHOLE base session
    colorbar;
    colormap(jet); % Use jet colormap
    caxis([0 1]); % Set color limits for correlation values
    axis square;
    title(['BASE SESSION', base_date,'Clustering']);
    xlabel('Neurons');
    ylabel('Neurons');

    % Change tick labels to original neuron indices
    xticks(1:length(sortedNeuronIndices));
    yticks(1:length(sortedNeuronIndices));
    xticklabels(string(sortedNeuronIndices)); % Label with original neuron numbers
    yticklabels(string(sortedNeuronIndices));
    xtickangle(90); % Rotate x-axis labels for better readability

    %uncomment to remove ticks/neuron labels and comment the previous 5 lines
    %xticks([]);
    %yticks([]);



%%



sgtitle([type_of_maze,' - ',date_sess, '   (base session : ', base_date,')']);



end