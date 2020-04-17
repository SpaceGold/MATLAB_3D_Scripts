% Takes in cropped ROIs; passes custom masks, open or closed. 
% Adam Zimmerman 2020
%% Instructions: 
% Download and install AZ_threshold_cleanup.m from github.com/SpaceGold/MATLAB_3D_Scripts
%   and ReadData3D from mathworks.com/matlabcentral/fileexchange/29344-read-medical-data-3d
% Check work by opening raw crop (e.g. test1_) in ITK-SNAP and loading.
%   open or closed mask as segmentation image.
% Begin by pasting local path to individually cropped, seeded ROIs.
%   If you don't have these yet, but have combined ROIs, download AZ_label_splitter.m.
% Tweak the parameters at the bottom of this script to optimize masks.
%   Add a break point in the for loop while optimizing. Click Run>Continue.
%   Delete inadequate mask files to make room for more.
%   Remember that quality may vary between ROIs, e.g. needing alt threshold.

%% User: insert path to cropped ROI files here:
cd 'C:\Users\amc39\Google Drive\ABC\Vignesh_SP';
%% 
clear global
clearvars
clc  
import ReadData3D_version1k.*; % may require download from link in instructions

% Check for Masks directory
doesMasksFolderExist = false;
if isempty(dir('Masks'))
    % create Masks directory
    mkdir('Masks');
    doesMasksFolderExist = true;
else
    disp('Mask folder found');
end

% Run 
cropFds = fileDatastore('test1_*', 'ReadFcn', @importdata);
cropFullNames = cropFds.Files; % get crop names
nCrop = size(cropFullNames, 1);
cropMatrix = [];
for crop = 1:nCrop % process each crop -> mask
    tic
    fullName = cropFullNames(crop);
    [newRt, cropName, ext] = fileparts(fullName{1});
    fnCrop = char([cropName ext]);
    rt = char(newRt);    
    
    % User: tweak values of parameters here. Explanations with defaults:
    %   threshold: removes label from voxels below (uint8 gray values)
    %   dilation & erosion kernels: radius for filling in gaps (voxels)
    %   connected components mode: 6, 18, or 26 (neighbor voxels)
    %   minimum connected component object size (voxels)
    %   boolean for whether you want to save hollow or filled in masks
    AZ_threshold_cleanup(rt, fnCrop, ...
        'thresh', 49,...
        'dKr', 1, 'eKr', 1,...
        'conn', 6,...
        'minCCsize', 2500,...
        'saveOpen', true, 'saveClosed', true);
    toc
end
%%