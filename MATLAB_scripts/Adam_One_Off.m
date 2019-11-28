% Adam One Off 
%% combine probability mask and raw

tic
min_P_bb = 0.3;
max_p_bk = 0.8;
minCsize = 40000;
minBBsize = 40000;
Threshold = false;
dilationKernel = 5;
percentileThreh = 99.9;
numberOFChannels = 2; % --> change to 3 if you have cilia
cd 'D:\He Lab Viz2\Doubles_Project_Viz2\done\P0_ROI3'
homeFolderPath = cd;


rt = char('D:\He Lab Viz2\Doubles_Project_Viz2\done\P0_ROI3'); % note the critical char conversion
imp = char('cilia_Probabilities2.tiff'); % assigning vars for GU_LH_cleanup
imr = char('Raw_ROI3_P0.tif');

for dilation = 1   % for single BB, latest good ratio: actually 1 dilation 2 erosion; 3,7 for cilia
    for erosion = 1 
        Adam_Alt_GU_LH_cleanupSemiAutomatedIlastikOutputs(rt, imp, imr,'min_P_bb', min_P_bb, 'max_p_bk',max_p_bk ,'minBBsize', ...
            minBBsize, 'minCsize', minCsize, ...
            'dkr_bb', dilation, 'dkr_c', dilation, 'ekr', erosion,'nCh', numberOFChannels);
    end
end    
toc

%%  if simply converting raw tif to mha:
clc 
% fnSegTif = 'D:\He Lab Viz2\Complete Mask Files\P0\ROI7_P0+Cilia_Movie\cilia_new\Thresh3_Cilia_ROI7_P3_standard.tif'; % read a TIF(f) file
% imRawTif = readtiff(fnSegTif); 
% mhaWriter([fnSegTif(1:end-4)  '.mha'], imRawTif, [1,1,1], 'uint8');
% 
% % optional
% mhaWriter([fnSegTif(1:end-4)  '_binary.mha'], logical(imRawTif), [1,1,1], 'uint8');

fnRawTif = 'D:\He Lab Viz2\Complete Mask Files\P0\ROI7_P0+Cilia_Movie\cilia_new\Thresh3_Cilia_ROI7_P3_standard.tif';
imRawTif = readtiff(fnRawTif); % read a TIF(f) file
mhaWriter([fnRawTif(1:end-4) '.mha'], logical(imRawTif), [1,1,1], 'uint8');
% imRawMha = mhaReader([fnRawTif(1:end-4) '.mha']); % ?? [imRawMha,~]?

%% combine ITK seg with raw, collapsing ITK channels to binary
clear
% filepath of raw tif file 
fnRawTif = 'D:\He Lab Viz2\Doubles_Project_Viz2\done\P0_ROI3\Raw_ROI3_P0.tif';
imRawTif = readtiff(fnRawTif); 
mhaWriter([fnRawTif(1:end-4) '.mha'], imRawTif, [1,1,1], 'uint8');
imRawMha = mhaReader([fnRawTif(1:end-4) '.mha']); % ?? [imRawMha,~]?

% label mha
fnLabels = 'D:\He Lab Viz2\Doubles_Project_Viz2\done\P0_ROI3\cilia\attempt2.1_pockmarked_stage4_eroded_binary_standard_binary.mha';
[imLabels,~] = mhaReader(fnLabels);
imBinaryLabels = logical(imLabels); % trying to solve output as doubles issue

newim = imBinaryLabels .* imRawMha; 
newim = permute(newim, [1, 2, 3]);
writetiff(uint8(newim), [fnLabels(1:end-4) '_standard.tif']);

% produce median filtered version too
medIm = medfilt3(imRawTif);
newim = medIm; 
newim(~logical(imBinaryLabels)) = 0;
writetiff(uint8(newim), [fnLabels(1:end-4) '_median_filtered.tif']);



%% Threshold tif to remove below certain value

clear
clc
fnSegTif = 'D:\He Lab Viz2\Doubles_Project_Viz2\done\P0_ROI3\cilia\stage3_cilia_labels_7_multicolor_P0_ROI3_median_filtered_thresh-4.dilated_thresh=106_binary_standard.tif';
imSegTif = readtiff(fnSegTif); 

% adjust here
threshold = 93; 
imSegTif(imSegTif<threshold) = 0; 
threshold = num2str(threshold); % prepare filename
writetiff(uint8(imSegTif), [fnSegTif(1:end-4) '_thresh=', threshold, '.tif']); 

% % write mha binary 
% mhaWriter([fnSegTif(1:end-4)  '_binary.mha'], imSegTif, [1,1,1], 'uint8');






%% fix / add missing pieces to BB seg

clear global
clearvars global
rt = 'D:\He Lab Viz2\Doubles_Project_Viz2\P14_ROI8\'; % must include \ at end

% filepath of raw tif file 
fnRawTif = 'ROI_8_P14-2_8x8x8nm_1.25MHz_95umX4000_4646_Y3029_3696_Z3100_3696.tif';
imRawTif = readtiff([rt fnRawTif]); 
% mhaWriter([fnRawTif(1:end-4) '.mha'], imRawTif, [1,1,1], 'uint8');
% imRawMha = mhaReader([fnRawTif(1:end-4) '.mha']); % ?? [imRawMha,~]?
medIm = medfilt3(imRawTif);

% label mha
fnLabels = 'cilia_labels_multicolor_P14_ROI8.mha';
[imLabels,~] = mhaReader([rt fnLabels]);
l = unique(imLabels(imLabels>0));
% 
% % dealing with high confidence missed regions
% T = thresholdOtsu(imRawTif(imLabels==2));
% FLabels = imLabels;
% % FLabels(imLabels ==3) = 0;
% FLabels(imLabels ==2 & imRawTif < T) = 0;
% FLabels = logical(FLabels);
% FLabels = imdilate(FLabels, strel('sphere',1));
% FLabels = imerode(FLabels, strel('sphere',1));

% threshold entire thing (experimental)
% T0 = thresholdOtsu(imRawTif(imLabels==1)); % commenting out for bug
% F0Labels = imLabels;
% F0Labels(imLabels & imRawTif < T0) = 0;
% F0Labels = logical(F0Labels);
% F0Labels = imdilate(F0Labels, strel('sphere',3));
% F0Labels = imerode(F0Labels, strel('sphere',0));

% dealing with low confidence potentially interesting regions
% T = thresholdOtsu(imRawTif(imLabels==3));
% FLabels(imLabels ==3 & imRawTif < T) = 0;

% imBinaryLabels = logical(imLabels); % trying to solve output as doubles issue
newim = imRawTif; 
% newim(~logical(FLabels)) = 0; % removing this fixed a bug of old img
newim(~logical(F0Labels)) = 0; % experimental

writetiff(uint8(newim), [rt fnLabels(1:end-4) '_BB_full_thresh_v3.tif']);
% 
% newim = medIm; 
% newim(~logical(imLabels)) = 0;
% % newim(~logical(FLabels)) = 0;
% % newim(~logical(F0Labels)) = 0; % experimental
% writetiff(uint8(newim), [rt fnLabels(1:end-4) '_BB_median_thresh_v3.tif']);
