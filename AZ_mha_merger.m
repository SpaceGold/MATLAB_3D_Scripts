% MetaImage .mha 3D segmentation label merger
% Adam Zimmerman, 2020

clc % Clear console; initialize directory & reader
cd 'C:\Users\amc39\Google Drive\ABC\ZF_Tailbud_Dev\ForAdam_segmentationCuration\ZF_tailbud_development\to_merge\'; % keep '\' at end
import ReadData3D_version1k.*;
pathName = pwd; % pwd means current directory
csv = readtable('..\..\..\Curation1_ZF_Tailbud_Dev - merge.csv');
csv = table2array(csv); % https://www.mathworks.com/matlabcentral/answers/487283-error-subscripting-a-table-using-linear-indexing-one-subscript-or-multidimensional-indexing-thre
%% merge label tuples from csv, organized by column=timepoint
clc
rows  = size(csv,1); % get max dimension y
cols  = size(csv,2); % get max dimension x
fds = fileDatastore('*.mha', 'ReadFcn', @importdata); % https://matlab.fandom.com/wiki/FAQ#How_can_I_process_a_sequence_of_files.3F
fullFileNames = fds.Files; % get volume names

for column = 1:cols % for each column
    if ~isempty(csv{1,column}) % if column not empty, initialize volume
        % Cnew = fullFileNames(cellfun('isempty', strfind(fullFileNames,'merged_'))); % ignore merged_
        fullName = fullFileNames(column); % prep filename
        [~, name, ext] = fileparts(fullName{1}); % set name and ext. (uses {1} to get name
        [volume,vol_info] = ReadData3D(fullFileNames{column}); % import data. IDK WHY this is {} not ()
        for row = 1:rows % for each row
            if ~isempty(csv{row, column}) % (y,x) if not empty
                temp_cell = csv{row, column}; % make new 2x1 cell
                cell_string = string(temp_cell); % of stringed tuple
                temp_cell = strsplit(cell_string, ','); % into 2 strings
                label_1 = str2double(temp_cell(1)); % into one int each
                label_2 = str2double(temp_cell(2));
                volume = changem(volume, label_1, label_2); % merge. (requires mapping toolkit). Must iterate over same volume, since changem makes a new one.
            end  
        end
        mhaWriter(['merged_', name, ext], volume, [0.256, 0.216, 0.3398], 'uint8'); % save % VOXEL SPACING HERE
        printout = sprintf('volume %d merged (%s)', column, name); % report
        disp(printout);  
    end
end
disp('done!');
