% Takes in cropped ROIs; passes custom masks
% Adam Zimmerman 2020
clear global
clearvars
clc  

%% Default, universal runner (inactive for Vignesh 4/23/20)
% rt = '/Users/GU/Desktop/Vignesh/initial_crops';
% fn = dir([rt filesep '*.mha']);
% fn = {fn.name};
% for i = 1:numel(fn)
%     tic
%     AZ_threshold_cleanup  (rt, fn{i});
%     toc
% end
%% Conditional runner (active for Vignesh 4/23/20)

rt = 'C:\Users\amc39\Google Drive\ABC\Vignesh_SP'; % set crop input folder

% User: populate list of desired 
verifiedList = ["*ROI1*_4.mha","*ROI1*_5.mha","*ROI1*_7.mha","*ROI1*_9.mha",...
   "*ROI2*_4.mha", "*ROI2*_5.mha","*ROI2*_6.mha", "*ROI2*_8.mha"]
for listMember = 1:numel(verifiedList)
    fn(listMember) = dir([rt filesep verifiedList{listMember}]);
end
fn = {fn.name}; 

for i = 1:numel(fn)
    tic
    GU_AZ_cavitySearch  (rt, fn{i});
    toc
end
%% Apr 23 good list
% *ROI1*_4.mha - Great!  - Would be a good test case
% *ROI1*_5.mha - Great! - Would be a good test case
% *ROI1*_7.mha - Great!  - Would be a good test case
% *ROI1*_9.mha - Great! - Would be a good test case
% *ROI2*_4.mha - Great! Few disconnected voxels near the edge of volume
% *ROI2*_5.mha - Great!  Few disconnected voxels near the edge of volume.
% *ROI2*_6.mha - Great! Would be a good test case
% *ROI2*_8.mha - Great! Would be a good test case
% 
% 
% '*ROI1*_4.mha','*ROI1*_5.mha','*ROI1*_4.mha','*ROI1*_5.mha', '*ROI2*_4.mha', '*ROI2*_5.mha','*ROI2*_6.mha', '*ROI2*_8.mha']

%% Apr 23 bad list
% 
% *ROI1*_1.mha - Voxels missing inside the nuclei (black) though the nuclear membrane is intact.
% *ROI1*_2.mha - Segmentation is good but part of the nuclei is clipped. Also seems like the segmented volume is not centered? (not sure if I am conveying this properly).
% *ROI1*_3.mha - Mostly great! There are a few disconnected voxels towards the edges and the nuclear membrane is sometimes clipped/cut at some locations. Maybe a tad bit more dilation here? 
% 
% *ROI1*_6.mha - Mostly good. Nuclei is clipped partially. A tad bit more dilation so that nuclear membrane is not clipped/cut.
% x
% *ROI1*_10.mha to *ROI1*_35.mha - Yet to be examined.
% 
% *ROI2*_1.mha - Voxels missing inside nuclei. Nuclei are clipped.
% *ROI2*_2.mha - Segmentation is good but nuclei is clipped/cropped.
% *ROI2*_3.mha - Not good. Weird clipped/cropping.
% 
% *ROI2*_7.mha - Not good. Nuclei seems completely weird/clipped.
% *ROI2*_9.mha to *ROI2*_22.mha - Yet to be examined.
