% Omits split MetaImage .mha 3D segmentation labels 
% Adam Zimmerman, 2020

clc % Initialize directory, reader, csv guide files
cd 'C:\Users\amc39\Google Drive\ABC\ZF_Tailbud_Dev\ForAdam_segmentationCuration\ZF_tailbud_development\to_split\'; % keep '\' at end
import ReadData3D_version1k.*;
split_csv = readtable('..\..\..\Curation1_ZF_Tailbud_Dev - split.csv');
split_csv = table2array(split_csv);
%% Omit split - get labels from csvs, organized by column=timepoint
clc
rows  = size(split_csv,1); % get max dimension y
cols  = size(split_csv,2); % get max dimension x
fds = fileDatastore('*.mha', 'ReadFcn', @importdata);
fullFileNames = fds.Files; % get volume names
for column = 1:cols % for each timepoint in csv guide file
    if ~isempty(split_csv{1,column}) % if column not empty, initialize volume
        fullName = fullFileNames(column); % prep filename
        [~, name, ext] = fileparts(fullName{1}); % set name and ext % (uses {1} to get name
        [volume,vol_info] = ReadData3D(fullFileNames{column}); % import volume data
        for row = 1:rows 
            if ~isempty(split_csv{row, column})
                temp_cell = split_csv{row, column}; % make new 2x1 cell
                cell_string = string(temp_cell); % of stringed tuple
                temp_cell = strsplit(cell_string, ','); % into n strings              
                n = size(temp_cell, 2); % get n of labels in cell
                label_matrix = []; % initialize temp matrix of labels
                for label = 1:n 
                    label_matrix(label) = str2double(temp_cell(label)); % one int each
                    volume = changem(volume, 0, label_matrix(label)); % merge 
                end
            end  
        end
        mhaWriter(['test_', name, '_split', ext], volume, [0.256, 0.216, 0.3398], 'uint8'); % save % VOXEL SPACING HERE
        printout = sprintf('volume %d split (%s)', column, name); % report
        disp(printout);  
    end
end
disp('done!');
