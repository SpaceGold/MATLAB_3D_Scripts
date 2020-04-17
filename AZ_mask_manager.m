% Takes in cropped ROIs; passes custom masks, open or closed. 
% Requires AZ_threshold_cleanup.m, 
% Adam Zimmerman 2020
clear global
clearvars
clc  

%% User: insert path to cropped ROI files:
cd 'C:\Users\amc39\Google Drive\ABC\Vignesh_SP';

%% Begin
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
for crop = 1:nCrop
    fullName = cropFullNames(crop);
    [newRt, cropName, ext] = fileparts(fullName{1});
    fnCrop = char([cropName ext]);
    rt = char(newRt);
    AZ_threshold_cleanup(rt, fnCrop)

end
%%