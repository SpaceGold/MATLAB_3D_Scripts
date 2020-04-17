function AZ_threshold_cleanup (rt, fnCrop, varargin)
% Takes in cropped raw ROI mha and returns an open and/or closed mask.
% Originally developed for masking a singled cropped FIB-SEM nucleus.
% Adam Zimmerman, 2020

ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('rt', @ischar); % root for new dir and masks
ip.addRequired('fnCrop', @ischar); % cropped raw data in
ip.addParameter('thresh', 49, @isnumeric); % threshold
ip.addParameter('dKr', 1, @isnumeric); % dilation kernel radius for gaps
ip.addParameter('eKr', 1, @isnumeric); % erosion kernel radius for gaps
ip.addParameter('conn', 6, @isnumeric); % conn mode: 6, 18, or 26
ip.addParameter('minCCsize', 1500, @isnumeric); % conn comp size in voxels
ip.addParameter('saveOpen', true, @islogical); % save open mask?
ip.addParameter('saveClosed', true, @islogical); % save closed mask?
ip.parse(rt, fnCrop, varargin{:});
p = ip.Results;

% load
% tic
[mask,~] = ReadData3D([rt filesep fnCrop]);

% threshold
mask(mask<p.thresh) = 0;
mask = logical(mask);

% dilate to fill some gaps
se_d = strel('sphere',p.dKr); % dilation
dilated_mask = imdilate(mask,se_d);

% erode
se_e = strel('sphere',p.eKr); 
eroded_mask = imerode(dilated_mask,se_e);
mask = eroded_mask;
% toc

%initialize all CC
ccIntReport = 'beginning connected component search';
disp(ccIntReport);
% tic
CC = bwconncomp(mask==1, p.conn); %survey the volume for connected components
% discard small components (assumed to be noise or debris on glass slide)
csize = cellfun(@numel, CC.PixelIdxList); % size of all objects in voxels
idx = csize>=p.minCCsize; % size of CC structure. default 1500 voxels
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
% toc
fprintf('CC %d is the largest at %d voxels\n', tag, highest);

%% if saving closed: fill in mask with solid binary voxels. Warning: buggy
if p.saveClosed == true
    % tic
    closedMemb = (zeros(size(ccMembrane)));
    for zSlice = 1:size(ccMembrane, 3) % iterate 2D workaround in lieu of alphaSpace()
        closedSlice = bwconvhull(ccMembrane(:,:,zSlice)); % bwconvhull() is 2D
        closedMemb(:,:,zSlice) = closedSlice;    
    end
    % toc
end
%% save open if doing so
if p.saveOpen == true
    % tic
    cd .\Masks % debugging
    fn_newim_1 = ['open_'... % cut rt filesep p.AnalysisPath filesep 
        'thresh' num2str(p.thresh)...
        '_dkr' num2str(p.dKr) '_ekr' num2str(p.eKr)...
        '_conn' num2str(p.conn) '_minCCsize' num2str(p.minCCsize) '_' fnCrop];
    mhaWriter(fn_newim_1, ccMembrane, [1,1,1], 'uint8');
    % toc
    saveReport1 = 'saved open mask';
    disp(saveReport1);
    cd ..
end
%% save closed if doing so
if p.saveClosed == true
    % tic
    cd .\Masks % debugging
    fn_newim_2 = ['closed_'... % cut rt filesep p.AnalysisPath filesep 
        'thresh' num2str(p.thresh)...
        '_dkr' num2str(p.dKr) '_ekr' num2str(p.eKr)...
        '_conn' num2str(p.conn) '_minCCsize' num2str(p.minCCsize) '_' fnCrop];
    mhaWriter(fn_newim_2, closedMemb, [1,1,1], 'uint8');   
    % toc
    saveReport2 = 'saved closed mask';
    disp(saveReport2);
    cd ..
end
end