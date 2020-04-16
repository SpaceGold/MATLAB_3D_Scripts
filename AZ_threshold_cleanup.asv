% function AZ_threshold_cleanup (rt, fn_raw, varargin)
% takes in cropped raw ROI mha and returns a segmented structure
% Adam Zimmerman, 2020

[mask,vol_info] = ReadData3D('C:\Users\amc39\Google Drive\ABC\Vignesh_SP\test1_ROI1_10x10x10bin_200kHz_align_inv_Seeded_label_16.mha'); % import label volume
       

thresh = 49; % <<<< set threshold for object of intrest (Vignesh's memb =< 58)


% threshold - not lining up properly
mask(mask<thresh) = 0;
mask = logical(mask);
% mhaWriter(['bthresh_16.mha'], mask, [1,1,1], 'uint8'); % save
%%
dKr = 1; % <<<< set dilation kernal size for dilation <<<<
eKr = 1; % <<<< set erosion kernal for erosion <<<<

% dilate to fill some gaps
se_d = strel('sphere',dKr); % dilation
dilated_mask = imdilate(mask,se_d);
% mhaWriter(['d1_thresh_16.mha'], dilated_mask, [1,1,1], 'uint8'); % save


% erode
se_e = strel('sphere',eKr); 
eroded_mask = imerode(dilated_mask,se_e);
% mhaWriter(['e1_thresh_16.mha'], eroded_mask, [1,1,1], 'uint8'); % save

mask = eroded_mask;


%% initialize all CC
clc
tic
CC = bwconncomp(mask==1, 6); %survey the volume for connected components
% discard small components (assumed to be noise or debris on glass slide)
csize = cellfun(@numel, CC.PixelIdxList); % size of all objects in voxels
idx = csize>=1000; % <<<<<<<<<<<<<<<<<<< EXPERIMENT WITH THIS
CC.NumObjects = sum(idx);
CC.PixelIdxList = CC.PixelIdxList(idx);
ccLen = length(CC.PixelIdxList);
ccCompound = labelmatrix(CC); % if ~=0 it collapses all to binary % n labels -> 1 vol
toc
%% select largest CC
% ccCompound = ccCompound == 5; % 3 happens to be the membrane for Vignesh in 1.16 for cc18; 5 for cc6
% mhaWriter(['ccc_16.mha'], ccCompound, [1,1,1], 'uint8'); % save
clc
tic
highest = 0;
tag = 0;
for element = 1:ccLen
    tempArray = CC.PixelIdxList(element);
    y = length(tempArray{1});
    if y > highest
        highest = y;  
        tag = element;
    end
end
toc
CC_report = sprintf('CC %d is the largest at %d voxels', tag, highest);
disp(CC_report);

% flag highest CC
ccMembrane = ccCompound == tag;

%%
% specifically for Vignesh, fill in label with solid binary voxels




% reintroduce raw data



% mhaWriter('ccM_16.mha', ccMembrane, [1,1,1], 'uint8'); % save

toc








% end