% Adam combine probability mask and raw

min_P_bb = 0.3;
max_p_bk = 0.8;
minCsize = 40000;
minBBsize = 100;
Threshold = false;
percentileThreh = 99.9;
numberOFChannels = 2; % --> change to 3 if you have cilia
clc; % clears command window
% 
% raw_prob_idx = 1:10;
% prob_raw_idx = 11:20;
% BBid = struct;
% BBFolderInfo = dir(rt);
% BBFolderInfo(1 : 2) = [];
% BBFileNames = {BBFolderInfo.name};
% 
% for BBidx = 1:10
%     imp = BBFileNames{BBidx};
% end
%   
% 
% for rawidx = 11:20
%     imr = BBFileNames{BBidx};
% end
%   

rt = 'D:\He Lab Viz2\For Adam\P14 SDA model\ROI_5_1_6SDA-files';
imp = 'ROI5_single_BB.view_corrected_Probabilities_stage3.tiff';
imr = 'ROI5_single_BB.view.tif';

for dilation = 1:2   
    for erosion = 1:2
        Adam_Alt_GU_LH_cleanupSemiAutomatedIlastikOutputs(rt, imp, imr,'min_P_bb', min_P_bb, 'max_p_bk',max_p_bk ,'minBBsize', ...
            minBBsize, 'minCsize', minCsize, ...
            'dkr_bb', dilation, 'dkr_c', dilation, 'ekr', erosion,'nCh', numberOFChannels);
    end
end    
