fn = 'D:\He Lab Viz2\Complete Mask Files\P14\ROI9_P14_BB+Cilia\BB_for_video_ROI9_P14.tif';
im = readtiff(fn);
gim = filterGauss3D(im,[1,1,1]);
T = thresholdOtsu(gim(im>0));
gim(gim<T) = 0; 
%%
tic
dtm = bwdist(~gim);
T = 20;
% T = thresholdOtsu(dtm(im>0));
dfim = dtm;
dfim(dtm<T) = 0;
toc

rp = regionprops3(logical(dfim));
%%
c =  {rp.Centroid}';

figure, 
for i = 1:size(c,1)
scatter3(c{i}(1),c{i}(2),c{i}(3), 'o', 'filled')
text(c{i}(1),c{i}(2),c{i}(3), num2str(i))
hold on

xlim([200 500])
ylim([00 400])
zlim([100 440])

% pause
end
xlabel('x') 
ylabel('y')
zlabel('z')

%%
figure, 
for i = 1:size(c,1)
scatter3(c{i,1}(1),c{i,1}(2), c{i,1}(3), 100, c{i,2},'o', 'filled')
% text(c{i}(1),c{i}(2),c{i}(3), num2str(i))
hold on

xlim([200 500])
ylim([00 400])
zlim([100 440])

% pause
end
xlabel('x')
ylabel('y')
zlabel('z')
colormap('jet')

%%
coord = [rp.Centroid];
X = coord(1:3:end);
Y = coord(2:3:end);
Z = coord(3:3:end);
mesh(X,Y,Z)