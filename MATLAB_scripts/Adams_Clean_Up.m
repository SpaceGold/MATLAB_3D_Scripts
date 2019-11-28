
%% SEGMENTATION COMBO SCRIPT - Adam Z.
% This script takes TIF raw, cleanup mask, and probability files 
% and combines them in the mha format to return a cleaner TIF.
% See testscript.m for previous version.
% Run section by section.

%%
% Step 0: generate prop in Ilastik; combine prob mask and raw to get segmentation file
min_P_bb = 0.3;
max_p_bk = 0.8;
minCsize = 10000;
minBBsize = 4000;
Threshold = false;
percentileThreh = 99.9;
numberOFChannels = 3; 

            rt = char('D:\He Lab Viz2\Complete Mask Files\E12.5\ROI5_E12.5_BB+Cilia'); % note the critical char conversion
            imp = char('Raw_BARE_Cut_Box_BB_ROI5_E12.5_Probabilities_all3_centriole_BARE.tiff'); % assigning vars for GU_LH_cleanup
            imr = char('Raw_BARE_Cut_Box_BB_ROI5_E12.5.tif');

for dilation = 7   % for single BB, latest good ratio: actually 1 dilation 2 erosion; 3,7 for cilia
    for erosion = 3 
        Adam_Alt_GU_LH_cleanupSemiAutomatedIlastikOutputs(rt, imp, imr,'min_P_bb', min_P_bb, 'max_p_bk',max_p_bk ,'minBBsize', ...
            minBBsize, 'minCsize', minCsize, ...
            'dkr_bb', dilation, 'dkr_c', dilation, 'ekr', erosion,'nCh', numberOFChannels);
    end
end    
%%
% Step 1: write tifs to binary mha; head over to ITK-SNAP

% 
% % filepath of segmentation file in need of correction
% fnSegTif = 'D:\He Lab Viz2\For Adam\P14 SDA model\3d_tif_folder\6 SDA candidates\E12.5\ROI_5-files\ROI_5_E12.5_n_6SDA.tif';
% imSegTif = readtiff(fnSegTif); % read a TIF(f) file
% mhaWriter([fnSegTif '_binary.mha'], logical(imSegTif), [1,1,1], 'uint8');

% filepath of raw file 
fnRawTif = 'D:\He Lab Viz2\Complete Mask Files\P0\ROI7_P0+Cilia_Movie\cilia_new\Thresh3_Cilia_ROI7_P3_standard.tif';
imRawTif = readtiff(fnRawTif); % read a TIF(f) file
mhaWriter([fnRawTif(1:end-4) '.mha'], imRawTif, [1,1,1], 'uint8');
imRawMha = mhaReader([fnRawTif(1:end-4) '.mha']); % ?? [imRawMha,~]?


%% 
% Step 2: build mask in ITK-SNAP

%%
% Step 3: load a mask with an image. mask has zeros and values 1+

% mask with all labels in mha
fnLabels = 'D:\He Lab Viz2\Single_BB_Project\Single_BB_5SDA_ROI9_P14\stage6_label_5SDA_BB_ROI9_P14.mha';
[imLabels,~] = mhaReader(fnLabels);

% split by label: 1 is bkgd, 2 is signal
% imLabels_bg = imLabels == 1;
% imLabels_obj = imLabels == 2;
% imLabels = logical(imLabels_obj);

% % If doing one off:
% writetiff(uint8(imLabels), [fnLabels(1:end-4) '_ITK.tif']);

%%
% Step 4: combine binary labels with seg file; enrich with raw

% segmentation file in binary
% [imBinarySeg,~] = mhaReader([fnSegTif '_binary.mha']); % old
imBinaryLabels = logical(imLabels); % trying to solve output as doubles issue

% combine binary segch2 and binary mask
%imBinaryCombo = imBinarySeg + imLabels_obj - imLabels_bg; % removed logical (). was logical trying to solve output as doubles issue

newim = imBinaryLabels .* imRawMha; % had this as labels x imRaw
% enrich binary combination with raw data
%newim = imBinaryCombo .* imRawMha; % UNCOMMENT
%mhaWriter([fnSegTif(1:end-4) '_corrected.mha'], (newim), [1,1,1], 'uint8');  
newim = permute(newim, [1, 2, 3]); % fixes dimension array error
writetiff(uint8(newim), [fnRawTif(1:end-4) '_corrected_ITK.tif']);

