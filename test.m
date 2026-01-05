inds_good = find(triu(ones(NUM_NERONS)-eye(NUM_NERONS)));

corrs_all = [corrMatrix_1(inds_good), corrMatrix_2(inds_good)];

for i =1:2
goodpairs{i} = find(~isnan(corrs_all(:,i)));
end


[h,p] = ttest(corrs_all(intersect(goodpairs{1},goodpairs{2}),1),corrs_all(intersect(goodpairs{1},goodpairs{2}),2));

figure
errorbar(nanmean(corrs_all),nanstd(corrs_all)./[sqrt(sum(~isnan(corrs_all)))] );shg
xlim([MIN MAX])
set(gca, 'XTick', 1:3, 'XTickLabel', {'Condition1','Condition2'});
title('Correlation Coefficients for Different Set-ups');
