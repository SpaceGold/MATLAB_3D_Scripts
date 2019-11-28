
%% MHA COMBO SCRIPT - Adam Z.
% This script takes TIF raw, cleanup mask, and probability files 
% and combines them in the mha format to return a cleaner TIF

% 
% % parameters need for GU_LU function at bottom of this script
% load('D:\He Lab Viz2\Complete Mask Files\alldata.mat');
% min_P_bb = 0.3;
% max_p_bk = 0.8;
% minCsize = 20000;
% minBBsize = 8000;
% Threshold = true;
% percentileThreh = 99.9;
% numberOFChannels = 2; % --> change to 3 if you have cilia
% 
% raw_prob_idx = [1:9, 22,23,27:34,36];
% prob_raw_idx = [10:21, 24:26,35:45];

% parfor_progress(numel(data));
% for k = 37%1:numel(data)
%     idx = ismember(k, raw_prob_idx);
%     if idx
%         [rt, imp,ext2] = fileparts(data(k).framePaths{1}{2});
%         [~, imr, ext1] = fileparts(data(k).framePaths{1}{1});
%     else
%         [rt, imp,ext2]  = fileparts(data(k).framePaths{1}{2});
%         [~, imr, ext1] = fileparts(data(k).framePaths{1}{4});
%     end
% 
%     GU_LH_cleanupSemiAutomatedIlastikOutputs(rt, [imp ext2], [imr ext1],'min_P_bb', min_P_bb, 'max_p_bk',max_p_bk ,'minBBsize', ...
%         minBBsize, 'minCsize', minCsize, ...
%         'dkr_bb', 7, 'dkr_c', 7, 'ekr', 3,'nCh', numberOFChannels, 'Threshold', Threshold);
%     parfor_progress;
% end
% % 
% % %
% % One off
% %             rt = char('D:\He Lab Viz2\Complete Mask Files\P14\ROI9_P14_BB+Cilia'); % ROI folder path; note the critical char conversion
% %             imp = char('probabilities3.tiff'); % filename; assigning vars for GU_LH_cleanup
% %             imr = char('Raw_ROI9_P14.tif'); % filename
% %             nCh = 3; % 3 if cilia
% %             i = 8;
% %             disp(rt); % can cut 
% %             GU_LH_cleanupSemiAutomatedIlastikOutputs(rt, imp, imr,'min_P_bb', min_P_bb, 'max_p_bk',max_p_bk ,'minBBsize', ...
% %                 minBBsize, 'minCsize', minCsize, ...
% %                 'dkr_bb', i, 'dkr_c', i, 'ekr', i-5,'nCh', numberOFChannels, 'Threshold', Threshold);
%%
% Skip this part for normal operation
% % write mha to logical tif of segmentation file
% 
% fnSegMha = 'D:\He Lab Viz2\For Adam\P14 SDA model\3d_tif_folder\ROI_9_9_5SDA\Analysis\clean_stage1_segch2_ekr1_dkrbb3_dkrc3_min_P_bb0.3_max_p_bk0.8_minBBsize8011_Raw_ROI9_P14.view.tif.mha';
% [imSegMha,~] = mhaReader(fnSegMha); % read a mha file
% writetiff(uint8(imSegMha),[fnSegMha(1:end-4) '_convertedfromMHA.tif']); % write binary 3D matrix into a tif file


% %%
% % Auxillary: write tif to mha, not binary
% 
% % filepath of segmentation file in need of correction
% fnSegTif = 'D:\He Lab Viz2\For Adam\P14 SDA model\3d_tif_folder\ROI_9_9_5SDA\segch2_ekr1_dkrbb3_dkrc3_min_P_bb0.3_max_p_bk0.8_minBBsize8011_Raw_ROI9_P14.view.tif';
% imSegTif = readtiff(fnSegTif); % read a TIF(f) file
% mhaWriter([fnSegTif '.mha'], (imSegTif), [1,1,1], 'uint8'); % write 3D matrix into a mha file 

%%
% Step 1: write tifs to binary mha; head over to ITK-SNAP

% filepath of segmentation file in need of correction
fnSegTif = 'D:\He Lab Viz2\For Adam\P14 SDA model\ROI_5_1_6SDA-files\stage0_segch2_ekr1_dkrbb3_dkrc3_min_P_bb0.001_max_p_bk0.8_minBBsize10_ROI5_single_BB.view.tif';
imSegTif = readtiff(fnSegTif); % read a TIF(f) file
mhaWriter([fnSegTif '_binary.mha'], logical(imSegTif), [1,1,1], 'uint8');

% filepath of raw file 
fnRawTif = 'D:\He Lab Viz2\For Adam\P14 SDA model\ROI_5_1_6SDA-files\ROI5_single_BB.view.tif';
imRawTif = readtiff(fnRawTif); % read a TIF(f) file
mhaWriter([fnRawTif(1:end-4) '.mha'], imRawTif, [1,1,1], 'uint8');
imRawMha = mhaReader([fnRawTif(1:end-4) '.mha']); % ?? [imRawMha,~]?


%% 
% load a mask with an image. mask has zeros and values 1+

% mask with all labels
fnLabels = 'D:\He Lab Viz2\For Adam\P14 SDA model\ROI_5_1_6SDA-files\stage1_cleanup.mha';
[imLabels,~] = mhaReader(fnLabels);

% split by label: 1 is bkgd, 2 is signal
imLabels_bg = imLabels == 1;
imLabels_obj = imLabels == 2;
testL = imLabels == 0;

%%
% combine binary labels with seg file; enrich with raw

% segmentation file in binary
[imBinarySeg,~] = mhaReader([fnSegTif '_binary.mha']);
imBinarySeg = logical(imBinarySeg); % trying to solve output as doubles issue

% combine binary segch2 and binary mask
imBinaryCombo = imBinarySeg + imLabels_obj - imLabels_bg; % removed logical (). was logical trying to solve output as doubles issue

% enrich binary combination with raw data
newim = imBinaryCombo .* imRawMha;
%mhaWriter([fnSegTif(1:end-4) '_corrected.mha'], (newim), [1,1,1], 'uint8');  
newim = permute(newim, [1, 2, 3]); % fixes dimension array error
writetiff(uint8(newim), [fnRawTif(1:end-4) '_corrected.tif']);

