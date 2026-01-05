function ttest_modified(mat1_folder, mat2_folder)

%load('D:\DBMC_bruker\m9399\23022025_patches\reordered_matrx.mat')% Linear track
%mat_corr1 = sortedCorrMatrix23;
load([mat1_folder,'\reordered_matrx.mat'],'sortedCorrMatrix23')
mat_corr1 = sortedCorrMatrix23;
%load('D:\DBMC_bruker\m9399\24022025_patches\reordered_matrx.mat')% Complex task
%mat_corr2 = sortedCorrMatrix;
%mat_corr2 = corr24;
load([mat2_folder,'\reordered_matrx.mat'],'sortedCorrMatrix')
mat_corr2 = sortedCorrMatrix;

% Extract upper triangle (excluding diagonal)
NUM_NEURONS = size(mat_corr1, 1);
inds_good = find(triu(ones(NUM_NEURONS) - eye(NUM_NEURONS)));
% Collect correlations into one array [cond1, cond2]
corrs_all = [mat_corr1(inds_good), mat_corr2(inds_good)];
% Keep only pairs that are valid in both conditions
goodpairs{1} = find(~isnan(corrs_all(:,1)));
goodpairs{2} = find(~isnan(corrs_all(:,2)));
valid_inds = intersect(goodpairs{1}, goodpairs{2});

% Paired t-test
[h, p] = ttest(corrs_all(valid_inds,1), corrs_all(valid_inds,2));
disp(['T-test result: h = ', num2str(h), ', p = ', num2str(p)]);

figure;
errorbar(nanmean(corrs_all),nanstd(corrs_all)./sqrt(sum(~isnan(corrs_all))));
set(gca, 'XTick', 1:2, 'XTickLabel', {'Linear Track', 'T-maze Task'});
xlim([0.5 2.5]);
ylabel('Mean Pairwise Correlation');
title(['Paired t-test p = ', num2str(p)]);
% Scatter plot of pairwise correlations (Linear Track vs T-maze)
figure;
scatter(corrs_all(valid_inds,1), corrs_all(valid_inds,2), 30, 'filled');
hold on;

% Plot y = x reference line (no change)
refline(1, 0);
xlabel('Pairwise Correlation - Linear Track');
ylabel('Pairwise Correlation - T-maze Task');
title('Neuron Pair Correlations Across Tasks');
axis square;
grid on;



figure;
hold on;
b = bar([mean(corrs_all(valid_inds,1)) mean(corrs_all(valid_inds,2))]);
set(b, 'LineWidth', 2);
er = errorbar([mean(corrs_all(valid_inds,1)) mean(corrs_all(valid_inds,2))],[std(corrs_all(valid_inds,1)) std(corrs_all(valid_inds,2))]/sqrt(22));
set(er, 'LineWidth', 2);
xt = [1.25];
yt = [0.6];
%str = 'p = 0.3326';
text(xt,yt,num2str(p),'FontSize',14)
text(1.4,0.57,'n.s.','FontSize',12)

% Vertical "caps" on the bracket
xt = [1 2];
yt = [0.55 0.55];
plot(xt,yt, 'k', 'LineWidth', 2);  % left cap



xlim([0 3])
hold off

% Calculate correlation between the correlation values (across neuron pairs)
[taskCorr_r, taskCorr_p] = corr(corrs_all(valid_inds,1), corrs_all(valid_inds,2));

% Display result
disp(['Correlation between pairwise correlations across tasks: r = ', ...
    num2str(taskCorr_r, '%.3f'), ', p = ', num2str(taskCorr_p, '%.4f')]);


end %end END