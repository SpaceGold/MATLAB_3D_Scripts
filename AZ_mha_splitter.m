% Omits split MetaImage .mha 3D segmentation labels 
% Adam Zimmerman, 202000

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

for column = 1:cols % for each column
    if ~isempty(split_csv{1,column}) % if column not empty, initialize volume
        fullName = fullFileNames(column); % prep filename
        [~, name, ext] = fileparts(fullName{1}); % set name and ext. (uses {1} to get name
        [volume,vol_info] = ReadData3D(fullFileNames{column}); % import data. IDK WHY this is {} not ()
        for row = 1:rows % for each row
            if ~isempty(split_csv{row, column}) % (y,x) if not empty
                temp_cell = split_csv{row, column}; % make new 2x1 cell
                cell_string = string(temp_cell); % of stringed tuple
                temp_cell = strsplit(cell_string, ','); % into 2 strings
                label_1 = str2double(temp_cell(1)); % into one int each
                label_2 = str2double(temp_cell(2));
                volume = changem(volume, label_1, label_2); % merge. (requires mapping toolkit). Must iterate over same volume, since changem makes a new one.
            end  
        end
        mhaWriter([name, '_split', ext], volume, [0.256, 0.216, 0.3398], 'uint8'); % save % VOXEL SPACING HERE
        printout = sprintf('volume %d split (%s)', column, name); % report
        disp(printout);  
    end
end
disp('done!');
