% MetaImage .mha 3D segmentation label merger
% Adam Zimmerman, 2020

clc % Initialize directory, reader, csv guide file
cd 'C:\Users\amc39\Google Drive\ABC\ZF_Tailbud_Dev\ForAdam_segmentationCuration\ZF_tailbud_development\to_merge\'; % keep '\' at end
import ReadData3D_version1k.*;
merge_csv = readtable('..\..\..\Curation1_ZF_Tailbud_Dev - merge.csv'); % load label csv files
merge_csv = table2array(merge_csv);
%% merge label tuples from csv, organized by column=timepoint
clc
rows  = size(merge_csv,1); % get max dimension y
cols  = size(merge_csv,2); % get max dimension x
fds = fileDatastore('*.mha', 'ReadFcn', @importdata);
fullFileNames = fds.Files; % get volume names

for column = 1:cols % for each column
    if ~isempty(merge_csv{1,column}) % if column not empty, initialize volume
        fullName = fullFileNames(column); % prep filename
        [~, name, ext] = fileparts(fullName{1}); % set name and ext. (uses {1} to get name
        [volume,vol_info] = ReadData3D(fullFileNames{column}); % import data. IDK WHY this is {} not ()
        for row = 1:rows % for each row
            if ~isempty(merge_csv{row, column}) % (y,x) if not empty
                temp_cell = merge_csv{row, column}; % make new 2x1 cell
                cell_string = string(temp_cell); % of stringed tuple
                temp_cell = strsplit(cell_string, ','); % into 2 strings
                label_1 = str2double(temp_cell(1)); % into one int each
                label_2 = str2double(temp_cell(2));
                volume = changem(volume, label_1, label_2); % merge. (requires mapping toolkit). Must iterate over same volume, since changem makes a new one.
            end  
        end
        mhaWriter(['03_m_', name, ext], volume, [0.256, 0.216, 0.3398], 'double'); % save % VOXEL SPACING HERE
        printout = sprintf('volume %d merged (%s)', column, name); % report
        disp(printout);  
    end
end
disp('done!');
