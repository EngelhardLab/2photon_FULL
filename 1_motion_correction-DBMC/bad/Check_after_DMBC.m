template_file = '/mnt/nas2/2Photon_Data/LIZA/Imaging_data/m4324/12252025/TSeries-12242025-1145-1537/Processed/template_mov_green.tif';
temp2 = loadTiffStack_single(template_file);
for l=1:size(temp2,3)
    tmp2_n(:,l) = reshape(temp2(:,:,l),512^2,1);
end
goodinds2 = find(triu(ones(size(temp2,3))-eye(size(temp2,3))));
tmpcrr2 = corr(tmp2_n);
t2_n = tmpcrr2(goodinds2);
figure
hist(t2_n(:),1e3);shg