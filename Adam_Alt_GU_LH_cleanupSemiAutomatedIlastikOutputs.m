function Adam_Alt_GU_LH_cleanupSemiAutomatedIlastikOutputs(rt, fn_probabilities, fn_raw, varargin)
% takes inputs for raw, uncertainties and probabilites from ilastik workflow
% Gokul Upadhyayula, 2019

% example usage
% GU_LH_cleanupSemiAutomatedIlastikOutputs('D:\test\ROI1_P14','Probabilities_ROI1_P14.tiff', 'Raw_ROI1_P14.tif',...
%     'min_P_bb', 0.3, 'max_p_bk', 0.8 ,'minBBsize', 4000, 'minCsize', 1000, ...
%     'dkr_bb', 3, 'dkr_c',5, 'ekr', 2,'nCh', 3);


ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('rt', @ischar);
ip.addRequired('fn_probabilities', @ischar);
ip.addRequired('fn_raw', @ischar);
ip.addParameter('AnalysisPath', 'Analysis', @ischar);
ip.addParameter('nCh', 2 , @isnumeric); % # of channels, if 2, assumes bb and bk in that order; if 3, assumes cilia, bk, bb
ip.addParameter('ekr', 2 , @isnumeric); % erosion kernel radius for bb and cilia
ip.addParameter('dkr_bb', 2 , @isnumeric); % dilation kernel radius for bb
% ip.addParameter('ekr_c', 2 , @isnumeric); % erosion kernel radius for cilia
ip.addParameter('dkr_c', 2 , @isnumeric); % dilation kernel radius for cilia
ip.addParameter('Threshold', false , @islogical); % related to raw, masked data --> followed by dilation with KR
ip.addParameter('min_P_bb', 0.3 , @isnumeric);
ip.addParameter('max_p_bk', 0.8 , @isnumeric);
ip.addParameter('minBBsize', 4000 , @isnumeric);
ip.addParameter('minCsize', 1000 , @isnumeric);
ip.addParameter('PT', 99.9, @isnumeric);% percentile threshold
ip.parse(rt, fn_probabilities, fn_raw, varargin{:});
p = ip.Results;

mkdir([rt filesep p.AnalysisPath]);
% fn{1} = fn_uncertanties; % uncertainty
fn{2} = fn_probabilities; % probabilities
fn{3} = fn_raw; % raw data

%% load data
tic
% read in the raw data
im = readtiff([rt filesep fn{3}]);
% mhaWriter([rt filesep fn{3} '.mha'], im, [1,1,1], 'uint8'); % TOO MUCH
% read in the probabilities -- separate background and Basal bodies (even vs. odd slices)
fileInfo = dir([rt filesep fn{2}]);
fileSize = fileInfo.bytes/1000^3;
if fileSize < 4
    tmp = readtiff([rt filesep fn{2}]);
     if p.nCh == 2
        im_p_bb = tmp(:,:,1:2:end); % separate bb
        im_p_bk = tmp(:,:,2:2:end); % separate bk
    elseif p.nCh ==3
        im_p_c = tmp(:,:,1:3:end); % separate cilia
        im_p_bk = tmp(:,:,2:3:end); % separate bk
        im_p_bb = tmp(:,:,3:3:end); % separate bb
    end
else
    [tmp,~] = imread_big([rt filesep fn{2}]);
%     tmp = single(mat2gray(tmp));
    if p.nCh == 2
        im_p_bb = tmp(:,:,1:2:end); % separate bb
        im_p_bb = single(mat2gray(im_p_bb));
        im_p_bk = tmp(:,:,2:2:end); % separate bk
       im_p_bk = single(mat2gray(im_p_bk));
    elseif p.nCh ==3
        im_p_c = tmp(:,:,1:3:end); % separate cilia
        im_p_c = single(mat2gray(im_p_c));
        im_p_bk = tmp(:,:,2:3:end); % separate bk
         im_p_bk = single(mat2gray(im_p_bk));
        im_p_bb = tmp(:,:,3:3:end); % separate bb
        im_p_bb = single(mat2gray(im_p_bb));
    end
end
toc

%% threshold probabilities of BB and background
tic
tmp = im_p_bb;
tmp(tmp <p.min_P_bb) = 0;
tmp(im_p_bk>p.max_p_bk) = 0;
toc

im_labels = zeros(size(tmp), 'uint8');
im_labels(tmp>0) = 1; % set bb as label 1

if p.nCh == 3
    tic
    tmp = im_p_c;
    tmp(tmp <p.min_P_bb) = 0;
    tmp(im_p_bk>p.max_p_bk) = 0;
    im_labels(tmp>0) = 2; % set cilia as label 2
    toc
end

%% clean up debris, fuse relatively connected comp via dilation of the data
tic
ese = strel('sphere',p.ekr); % define kernel
dse_bb = strel('sphere',p.dkr_bb); % define kernel
dse_c = strel('sphere',p.dkr_c); % define kernel
% cm = logical(tmp); % initializing candidate voxels for BB
% cm = imerode(cm, se); % errode (removes sharp lines)
cm = GU_erodeLabels(im_labels, ese);

if p.nCh ==2
    ms = p.minCsize;
else
    ms = p.minBBsize;
end

CC = bwconncomp(cm==1, 26); %survey the volume for connected components
% discard small components (assumed to be noise or debris on glass slide)
csize = cellfun(@numel, CC.PixelIdxList); % size of all objects in voxels
idx = csize>=ms; % index potential candidates for bb
CC.NumObjects = sum(idx);
CC.PixelIdxList = CC.PixelIdxList(idx);
mask = labelmatrix(CC)~=0; 
if p.nCh ==2
    se = dse_c;
else
    se = dse_bb;
end
mask = imdilate(mask, se); % dilate to connect disconnected objects from earlier erosion
newim_1 = zeros(size(im),'uint8'); % reinitialize raw data
newim_1(mask) = im(mask); % set everything outside the mask to zero
% save segmented
tic
fn_newim_1 = [rt filesep p.AnalysisPath filesep 'segch2_' 'ekr' num2str(p.ekr) '_dkrbb' num2str(p.dkr_bb) '_dkrc' num2str(p.dkr_c) '_min_P_bb' num2str(p.min_P_bb) '_max_p_bk' num2str(p.max_p_bk) '_minBBsize' num2str(p.minBBsize) '_' fn_probabilities];
writetiff(newim_1, fn_newim_1);
% mhaWriter([fn_newim_1 '.mha'], newim_1, [1,1,1], 'uint8'); % TOO MUCH
% mhaWriter([fn_newim_1 '_binary.mha'], logical(newim_1), [1,1,1], 'uint8'); % TOO MUCH
toc

if p.nCh == 3
    CC = bwconncomp(cm==2, 26); %survey the volume for connected components
    % discard small components (assumed to be noise or debris on glass slide)
    csize = cellfun(@numel, CC.PixelIdxList); % size of all objects in voxels
    idx = csize>=p.minCsize; % index potential candidates for bb
    CC.NumObjects = sum(idx);
    CC.PixelIdxList = CC.PixelIdxList(idx);
    mask = labelmatrix(CC)~=0;
    mask = imdilate(mask, dse_bb); % dilate to connect disconnected objects from earlier erosion
    newim_2 = zeros(size(im),'uint8'); % reinitialize raw data
    newim_2(mask) = im(mask); % set everything outside the mask to zero
    tic
    fn_newim_2 = [rt filesep p.AnalysisPath filesep 'segCh3_' 'ekr' num2str(p.ekr) '_dkrbb' num2str(p.dkr_bb) '_dkrc' num2str(p.dkr_c) '_min_P_bb' num2str(p.min_P_bb) '_max_p_bk' num2str(p.max_p_bk) '_minBBsize' num2str(p.minBBsize) '_' fn_probabilities];
    writetiff(newim_2, fn_newim_2);
%     mhaWriter([fn_newim_2 '.mha'], newim_2, [1,1,1], 'uint8'); % TOO MUCH
% mhaWriter([fn_newim_2 '_binary.mha'], logical(newim_2), [1,1,1], 'uint8'); % TOO MUCH
    toc
end
toc

%%
if p.Threshold
    tic
    t = thresholdOtsu(newim_1(newim_1>0 & newim_1<prctile(newim_1(newim_1>0),p.PT)));
    newim_1(newim_1<t) = 0;
    cm = logical(newim_1);
%     cm = imdilate(cm, se);
    newim_1 = im; % reinitialize raw data
    newim_1(~cm) = 0; % set everything outside the mask to zero
    writetiff(newim_1, [rt filesep p.AnalysisPath filesep 'thres_seg_'  'ekr' num2str(p.ekr) '_dkrbb' num2str(p.dkr_bb) '_dkrc' num2str(p.dkr_c) '_min_P_bb' num2str(p.min_P_bb) '_max_p_bk' num2str(p.max_p_bk) '_minBBsize' num2str(p.minBBsize) '_' fn_probabilities]);
%     mhaWriter([fn_newim_1 '_thresh.mha'], newim_1, [1,1,1], 'uint8'); % TOO MUCH
%     mhaWriter([fn_newim_1 '_thresh_logical.mha'], logical(newim_1), [1,1,1], 'uint8'); % TOO MUCH
    toc
end