function GU_AZ_cavitySearch (rt, fnCrop, varargin)
% Takes in cropped raw ROI mha and returns an cavity masked volume
% Originally developed for segmenting nuclei in cropped FIB-SEM volumes
% Adam Zimmerman, 2020
% Gokul Upadhyayula, April 2020

% %% sample search and execution
% rt = '/Users/GU/Desktop/Vignesh/initial_crops';
% fn = dir([rt filesep '*.mha']);
% fn = {fn.name};
% 
% for i = 1:numel(fn)
%     tic
%     AZ_threshold_cleanup  (rt, fn{i});
%     toc
% end


ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('rt', @ischar); % root for new dir and masks
ip.addRequired('fnCrop', @ischar); % cropped raw data in
ip.addParameter('thresh', [], @isnumeric); % threshold
ip.addParameter('multiOtsuLevel', 2, @isnumeric); % multi level otsu threshold
ip.addParameter('maxIntensityPercentile', 99, @isnumeric); % multi level otsu threshold
ip.addParameter('dKr', 1, @isnumeric); % dilation kernel radius for gaps
ip.addParameter('eKr', 1, @isnumeric); % erosion kernel radius for gaps
ip.addParameter('final_dKr', 7, @isnumeric); % dilation kernel to make sure to get the nucleus and surrounding areas
ip.addParameter('conn', 26, @isnumeric); % conn mode: 6, 18, or 26
ip.addParameter('minCCsize', [], @isnumeric); % conn comp size in voxels -- if empty, will discard everything but max
ip.addParameter('cavityseeds', {}, @iscell); % a cell array of y,x,z coordinates of nuclei; if empty, it will use stack center as label ref
% ip.addParameter('saveOpen', true, @islogical); % save open mask? ------commented out for now
% ip.addParameter('saveClosed', true, @islogical); % save closed mask?
ip.parse(rt, fnCrop, varargin{:});
p = ip.Results;


% load
% tic
[im,~] = mhaReader([rt filesep fnCrop]);
mask = im;

[Gmag,~,~] = imgradient3(mask);
GmagE = imerode(logical(Gmag),strel('sphere',5)) .* Gmag;
mask = GmagE;

% threshold
if isempty(p.thresh)
    mlot = multithresh(mask(mask>0 & mask < prctile(mask(:), p.maxIntensityPercentile)),p.multiOtsuLevel);
    mask(mask<mlot(end)) = 0;
else
    mask(mask<p.thresh) = 0;
end
mask = logical(mask);

% dilate to fill some gaps
se_d = strel('sphere',p.dKr); % dilation
dilated_mask = imdilate(mask,se_d);

% erode
se_e = strel('sphere',p.eKr);
eroded_mask = imerode(dilated_mask,se_e);
mask = eroded_mask;

% border effects
bm = im == 0;
border = bwperim(bm);
border = imdilate(border,se_d);
se_d = strel('sphere',p.dKr*4);
bm = imdilate(bm,se_d);
% toc

%initialize all CC
ccIntReport = 'beginning connected component search';
disp(ccIntReport);
% tic
CC = bwconncomp(mask, p.conn); %survey the volume for connected components
% discard small components (assumed to be noise or debris on glass slide)
csize = cellfun(@numel, CC.PixelIdxList); % size of all objects in voxels
if ~isempty(p.minCCsize)
    idx = csize>=p.minCCsize; % size of CC structure. default 1500 voxels
else
    idx = csize == max(csize);
end
CC.NumObjects = sum(idx);
CC.PixelIdxList = CC.PixelIdxList(idx);
ccLen = length(CC.PixelIdxList);
ccCompound = labelmatrix(CC); % n labels -> 1 vol; if ~=0, collapses all to binary
se_d = strel('sphere',p.dKr*2); % dilation
ccMembrane = imdilate(logical(ccCompound),se_d);

%% identify the largest cavity
dtm = bwdist(ccMembrane); %distance transform
dtm(logical(ccMembrane)) = 0; % remove dilated boundary now for clean separation
dtm(border) = 0;
dtm(bm) = 0;

[sy, sx, sz] = size(dtm);
% mm = dtm(sy/2-p.cavitySearch(2):sy/2+p.cavitySearch(2), sx/2-p.cavitySearch(1):sx/2+p.cavitySearch(1), sz/2-p.cavitySearch(3):sz/2+p.cavitySearch(3));
% midx = find(dtm==max(mm(:))); % find the largest cavity near the center
se_e = strel('sphere',p.eKr*2);
dtm = imerode(logical(dtm),se_e);
[bl, n] = bwlabeln(logical(dtm)); % generate labels for discrete objects
if ~isempty(p.cavityseeds)
    for il = 1:numel(p.cavityseeds)
        loi(il) = bl(p.cavityseeds{il}); %labels of interest
    end
else
    loi = bl(round(sy/2), round(sx/2), round(sz/2));
end
moi = ismember(bl, loi);
se_d = strel('sphere',p.final_dKr); % dilation
ccMembrane = imdilate(logical(moi),se_d);
ccMembrane = uint8(ccMembrane).*uint8(im);

%% save
fn_newim_2 = ['HD_mask_'... % cut rt filesep p.AnalysisPath filesep
        'finaldkr_' num2str(p.final_dKr)...
        '_dkr' num2str(p.dKr) '_ekr' num2str(p.eKr)...
        '_' fnCrop];
mydir  = pwd; % get folder of raw
idcs   = strfind(mydir,filesep);
newdir = mydir(1:idcs(end)-1); % go up one folder
srt = [newdir filesep 'HD_segmentedCavity'];
mkdir(srt); % create save folder
mhaWriter([srt filesep fn_newim_2], ccMembrane, [1,1,1], 'uint8');

%% % select largest CC
% highest = 0;
% tag = 0;
% for element = 1:ccLen
%     tempArray = CC.PixelIdxList(element);
%     y = length(tempArray{1});
%     if y > highest
%         highest = y;
%         tag = element;
%     end
% end
% ccMembrane = ccCompound == tag; % flag highest CC
% toc
% fprintf('CC %d is the largest at %d voxels\n', tag, highest);

% %% if saving closed: fill in mask with solid binary voxels. Warning: buggy
% if p.saveClosed == true
%     % tic
%     closedMemb = (zeros(size(ccMembrane)));
%     for zSlice = 1:size(ccMembrane, 3) % iterate 2D workaround in lieu of alphaSpace()
%         closedSlice = bwconvhull(ccMembrane(:,:,zSlice)); % bwconvhull() is 2D
%         closedMemb(:,:,zSlice) = closedSlice;
%     end
%     % toc
% end
% %% save open if doing so
% if p.saveOpen == true
%     % tic
%     cd .\Masks % debugging
%     fn_newim_1 = ['open_'... % cut rt filesep p.AnalysisPath filesep
%         'thresh' num2str(p.thresh)...
%         '_dkr' num2str(p.dKr) '_ekr' num2str(p.eKr)...
%         '_conn' num2str(p.conn) '_minCCsize' num2str(p.minCCsize) '_' fnCrop];
%     mhaWriter(fn_newim_1, ccMembrane, [1,1,1], 'uint8');
%     % toc
%     saveReport1 = 'saved open mask';
%     disp(saveReport1);
%     cd ..
% end
% %% save closed if doing so
% if p.saveClosed == true
%     % tic
%     cd .\Masks % debugging
%     fn_newim_2 = ['closed_'... % cut rt filesep p.AnalysisPath filesep
%         'thresh' num2str(p.thresh)...
%         '_dkr' num2str(p.dKr) '_ekr' num2str(p.eKr)...
%         '_conn' num2str(p.conn) '_minCCsize' num2str(p.minCCsize) '_' fnCrop];
%     mhaWriter(fn_newim_2, closedMemb, [1,1,1], 'uint8');
%     % toc
%     saveReport2 = 'saved closed mask';
%     disp(saveReport2);
%     cd ..
% end
end