% divide one tiff stack of multiple cells into individual segmented ROIs & masks
% Adam Zimmerman 2020

% clear global
% clearvars
clc             % read HD stack
cd 'Z:\Vignesh\RawDataStacks\ROI2_4x4x4nm_200kHz_align_tif\';
rt = 'Z:\Vignesh\RawDataStacks\ROI2_4x4x4nm_200kHz_align_tif\'; % <<<< set raw stack path <<<<
srt = 'Z:\Vignesh\initial_crops\HD_Crops_tiff';% <<<< set output path <<<<
rawSlices = dir(['*.tif']);    
rawSlices = {rawSlices.name};
tic
imtmp = readtiff([rt rawSlices{1}]);
[sy, sx] = size(imtmp);
rawVolume = zeros([sy, sx, numel(rawSlices)], 'uint8');

for k = 1:numel(rawSlices)
   rawVolume(:,:,k) = readtiff([rt rawSlices{k}]);
end
toc
%% read label set, upscale it, and confirm it fits data
tic
rt = 'Z:\Vignesh\initial_crops\source'; % <<<< set label path <<<<
labelSetName = 'ROI2_10x10x10bin_200kHz_align_inv_Seeded.mha'; % <<<< set label name <<<<

[binnedLabelVolume, ~] = mhaReader([rt filesep labelSetName]); % read binned label in
[lsy, lsx, lsz] = size(binnedLabelVolume);
% HDlabelVolume = zeros([lsy*10, lsx*10, lsz*10], 'uint8'); 
binnedLabelVolume = uint8(binnedLabelVolume); % convert from double to uint8
HDlabelVolume = imresize3(binnedLabelVolume, 10, 'nearest');

if size(HDlabelVolume) ~= size(rawVolume) % validate and report label files match raw files
    countError = 'Label does not fit data (mismatch in dimensions).';
    disp(countError);
end
toc
%% locate conn comps; dilate, erode, and crop around them; then upscale, combine, finish

[binnedLabelVolume, ~] = mhaReader([rt filesep labelSetName]); % read binned label in
dKr = 50; % <<<< set dilation kernal size for dilation <<<<
eKr = 3; % <<<< set erosion kernal for erosion <<<<
thresh = 58; % <<<< set threshold for object of interest (Vignesh's memb =< 58)

[labelMatrix, nLabels] = bwlabeln(binnedLabelVolume, 26); % get 26-conn objects
labelReport = sprintf('%d labels found in %s', nLabels, labelSetName); disp(labelReport);

% initialize folder of Gokul's segmented cavity masks
gokulMaskRt = 'Z:\Vignesh\initial_crops\segCav\ROI2'; % <<<< set <<<<
cd 'Z:\Vignesh\initial_crops\segCav\ROI2';
gokulMaskList = dir(['*.mha']);
gokulMaskList = {gokulMaskList.name};

for label = 1:nLabels % w/n label set, dilate, crop, erode, save masks
    progress = sprintf('Processing mask %d',label); disp(progress);
    tic
    mask = labelMatrix == label; % make full size volume of just 1 label
    se = strel('sphere',dKr); % dilation
    dilatedMask = imdilate(mask,se);
    center = regionprops3(dilatedMask, 'centroid'); % prep for crop
    mask = dilatedMask;
    toc
    tic
    idx = find(mask); % log nonzero voxels 
    [ny,nx,nz] = size(mask); % get crop 
    [yi,xi,zi] = ind2sub([ny,nx,nz], idx); % get coordinates of all crop voxels
    b = 5; % boundary buffer of pixels for cropping
    xa = max(min(xi)-b,1):min(max(xi)+b,nx); 
    ya = max(min(yi)-b,1):min(max(yi)+b,ny);
    za = max(min(zi)-b,1):min(max(zi)+b,nz);
    xaHD = 10* max(min(xi)-b,1)-4:10* min(max(xi)+b,nx)+5; % 10x the min, 10x the max, and fill in?
    yaHD = 10* max(min(yi)-b,1)-4:10* min(max(yi)+b,ny)+5;
    zaHD = 10* max(min(zi)-b,1)-4:10* min(max(zi)+b,nz)+5;
    croppedMask = mask(ya,xa,za); % crop mask
    [csy, csx, csz] = size(croppedMask);
    
    % replace croppedMask with upscaled version of Gokul mask
%     tempMask = zeros([csy, csx, csz], 'logical');
    gokulMask0 = (mhaReader([gokulMaskRt filesep gokulMaskList{label}]));
    gokulMask = (gokulMask0);
    tempMask = uint8(gokulMask);
    tempMask = imresize3(tempMask, 10, 'nearest'); %  <<<< 10x
    finalMask = im2uint8(logical(tempMask)); % blank output bug until im2uint8
    
%     % crop cube cutout of rawVolume
    rawCrop = rawVolume(yaHD, xaHD, zaHD);
    % combine
    finalCrop = rawCrop .* (finalMask);
    finalCrop = im2uint8(finalCrop);
    toc
    tic
%     % save mask and crop
    writetiff(finalMask, [srt filesep 'HD_mask_' labelSetName(1:end-11) sprintf('_label_%d',label) '.tif']); % save
    writetiff(finalCrop, [srt filesep 'HD_crop_' labelSetName(1:end-11) sprintf('_label_%d',label) '.tif']); % save
   toc  
    cropReport = sprintf('Mask %d cropped and saved',label); disp(cropReport);
end