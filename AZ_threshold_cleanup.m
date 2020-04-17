function AZ_threshold_cleanup (rt, fn_raw, varargin)
% Takes in cropped raw ROI mha and returns an open and/or closed mask.
% Originally developed for masking a singled cropped FIB-SEM nucleus.
% Adam Zimmerman, 2020

ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('rt', @ischar); % root for new dir and masks
ip.addParameter('AnalysisPath', 'Masks', @ischar); % new dir
ip.addRequired('fn_crop', @ischar); % cropped raw data in
ip.addParameter('thresh', 48, @isnumeric); % threshold
ip.addParameter('dKr', 1, @isnumeric); % dilation kernel radius for gaps
ip.addParameter('eKr', 1, @isnumeric); % erosion kernel radius for gaps
ip.addParameter('conn', 18, @isnumeric); % conn mode: 6, 18, or 26
ip.addParameter('minCCsize', 1500, @isnumeric); % conn comp size in voxels
ip.addParameter('save open', 1, @isboolean); % save open mask?
ip.addParameter('save closed', 1, @isboolean); % save closed mask?

p = ip.Results;
mkdir([rt filesep p.AnalysisPath]);

% load
tic
[mask,~] = ReadData3D([rt filesep fn_crop]);

% threshold
mask(mask<thresh) = 0;
mask = logical(mask);

% dilate to fill some gaps
dKr = 1;
eKr = 1;
se_d = strel('sphere',dKr); % dilation
dilated_mask = imdilate(mask,se_d);

% erode
se_e = strel('sphere',eKr); 
eroded_mask = imerode(dilated_mask,se_e);
mask = eroded_mask;
toc

%initialize all CC
ccIntReport = 'beginning connected component search';
disp(ccIntReport);
tic
CC = bwconncomp(mask==1, conn); %survey the volume for connected components
% discard small components (assumed to be noise or debris on glass slide)
csize = cellfun(@numel, CC.PixelIdxList); % size of all objects in voxels
idx = csize>=minCCsize; % size of CC structure. default 1500 voxels
CC.NumObjects = sum(idx);
CC.PixelIdxList = CC.PixelIdxList(idx);
ccLen = length(CC.PixelIdxList);
ccCompound = labelmatrix(CC); % n labels -> 1 vol; if ~=0, collapses all to binary 

% select largest CC
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
ccMembrane = ccCompound == tag; % flag highest CC
toc
fprintf('CC %d is the largest at %d voxels\n', tag, highest);

%% if saving closed: fill in mask with solid binary voxels. Warning: buggy
if closed == 1
    tic
    closedMemb = FALSE(zeros(size(ccMembrane)));
    for zSlice = 1:size(ccMembrane, 3) % iterate 2D workaround in lieu of alphaSpace()
        closedSlice = bwconvhull(ccMembrane(:,:,zSlice)); % bwconvhull() is 2D
        closedMemb(:,:,zSlice) = closedSlice;    
    end
    toc
end
%% save open if doing so
if open == 1
tic
    fn_newim_1 = [rt filesep p.AnalysisPath filesep 'open_'...
        'thresh' num2str(p.thresh)...
        '_dkr' num2str(p.dkr) '_ekr' num2str(p.ekr)...
        'conn' conn '_minCCsize' num2str(p.minCCsize) 'fn_crop'];
    mhaWriter(fn_newim_1, ccMembrane, [1,1,1], 'uint8');
    toc
    saveReport1 = 'saved open mask';
    disp(saveReport1);
end
%% save closed if doing so
if closed == 1
    tic
    fn_newim_2 = [rt filesep p.AnalysisPath filesep 'closed_'...
        'thresh' num2str(p.thresh)...
        '_dkr' num2str(p.dkr) '_ekr' num2str(p.ekr)...
        'conn' conn '_minCCsize' num2str(p.minCCsize) 'fn_crop'];
    mhaWriter(fn_newim_2, closedMemb, [1,1,1], 'uint8');   
    toc
    saveReport2 = 'saved closed mask';
    disp(saveReport2);
end
end