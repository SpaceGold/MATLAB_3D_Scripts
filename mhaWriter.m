function mhaWriter(filename, img, resolution, data_type) % from gokul

[pathstr,name, ext]=fileparts(filename);
fid=fopen(filename, 'w');
if(fid<=0)
    printf('Impossible to open file %s\n', filename);
end

s = size(img);

if numel(s) == 2
    fprintf(fid, 'NDims = 2\n'); % Change this to the number of dimensions in your data set
    fprintf(fid, 'DimSize = %d %d\n', size(img,1), size(img,2) );%should reflect number of dimensions
    if(strcmp(data_type, 'char') || strcmp(data_type, 'uint8'))
        fprintf(fid, 'ElementType = MET_UCHAR\n');
    elseif(strcmp(data_type, 'short'))
        fprintf(fid, 'ElementType = MET_SHORT\n');
    elseif(strcmp(data_type, 'float'))
        fprintf(fid, 'ElementType = MET_FLOAT\n');
    elseif(strcmp(data_type, 'double'))
        fprintf(fid, 'ElementType = MET_DOUBLE\n');
    end
    fprintf(fid, 'ElementSpacing = %1.4f %1.4f\n', resolution(1), resolution(2) ); % should reflect number of dimensions
else
    fprintf(fid, 'NDims = 3\n'); % Change this to the number of dimensions in your data set
    fprintf(fid, 'DimSize = %d %d %d\n', size(img,1), size(img,2), size(img,3));%should reflect number of dimensions
    if(strcmp(data_type, 'char') || strcmp(data_type, 'uint8'))
        fprintf(fid, 'ElementType = MET_UCHAR\n');
    elseif(strcmp(data_type, 'short'))
        fprintf(fid, 'ElementType = MET_SHORT\n');
    elseif(strcmp(data_type, 'float'))
        fprintf(fid, 'ElementType = MET_FLOAT\n');
    elseif(strcmp(data_type, 'double'))
        fprintf(fid, 'ElementType = MET_DOUBLE\n');
    end
    fprintf(fid, 'ElementSpacing = %1.4f %1.4f %1.4f\n', resolution(1), resolution(2), resolution(3));
end


fprintf(fid, 'ElementByteOrderMSB = False\n');

if isequal(ext,'.mhd')
    fprintf(fid, 'ElementDataFile = %s\n', strcat(name, '.raw')); % Actual data file. File can have any extension
    if isempty(pathstr)
        img_filename = strcat(name, '.raw');
    else
        img_filename = strcat(pathstr, '/', name, '.raw');
    end
    fid2=fopen( img_filename, 'w')
    if(fid2<=0)
        %printf('Impossible to open file %s\n', img_filename);
    end
    fwrite(fid2, img, data_type);
    fclose(fid2);

else
    fprintf(fid, 'ElementDataFile = LOCAL\n'); % Actual data file. File can have any extension
    fwrite(fid, img, data_type);
end
fclose(fid);