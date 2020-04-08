% label splitter - divide sets of combined mha labels into individual ROIs per label
% Adam Zimmerman 2020
clc  % begin generic file management code...
cd 'C:\Users\amc39\Google Drive\ABC\Vignesh_SP\';
fds = fileDatastore('*Seeded.mha', 'ReadFcn', @importdata); % grab all label sets
fullFileNames = fds.Files; % get set names, e.g. ROI1.mha, ROI2.mha...
setCount = size(fullFileNames, 1); % loop through several sets
for set = 1:setCount
    fullName = fullFileNames(set);
    [rt, name, ext] = fileparts(fullName{1}); % set name and ext
    [volume,vol_info] = ReadData3D(fullFileNames{set}); % import volume data
    [labelMatrix, labelCount] = bwlabeln(volume, 26); % search for 26-connected objects
    report = sprintf('%d labels found in %s', labelCount, name); disp(report);
    for label = 4:labelCount % for each label in set, dilate, save
       tic
       temp_vol = labelMatrix == label; % make a volume of just n
       %mhaWriter(['test_all_', name, sprintf('label_%d',label), ext], mask, [1,1,1], 'uint8'); % save
       %temp_vol = zeros(size(labelMatrix),'uint8'); % reinitialize raw data
       %temp_vol(mask) = labelMatrix(mask); % set everything outside the mask to zero
       se = strel('sphere',8); % set structured element for dilation
       dilated_vol = imdilate(temp_vol,se);
       mhaWriter(['test_', name, sprintf('label_%d',label), ext], dilated_vol, [1,1,1], 'uint8'); % save
       size(dilated_vol, 1)
       toc
       
    end
    
end
