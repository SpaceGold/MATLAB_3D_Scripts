function [Im info] = mhaReader(filename)


Im = [];
precision = [];
p = find(filename == '/');

if ~isempty(p)
    direct = filename(1:p(end));
else
    direct=[];
end

fid = fopen(filename, 'r');

if (fid <= 0)
%     printf('Unable to open file %s\n', filename);
end

info.ElementNumberOfChannels = 1;

line = fgetl(fid);
while ( ~isempty(line) )
    pos = find(line == '=');
    type = line(1:pos-2);
    if isempty(type)
        break;
    end
    switch type
        case 'ObjectType'
            A = sscanf(line, 'ObjectType = %s');
            info.ObjectType = A;
        case 'NDims'
            A = sscanf(line, 'NDims = %d');
            info.NDims = A;
        case 'BinaryData'
            A = sscanf(line, 'ObjectType = %s');
            info.ObjectType = A;
        case 'ElementByteOrderMSB'
            A = sscanf(line, 'ElementByteOrderMSB = %s');
            if (strcmpi(A, 'true'))
                info.BinaryData = true;
            else
                info.BinaryData = false;
            end
        case 'CompressedData'
            A = sscanf(line, 'CompressedData = %s');
            if (strcmpi(A, 'true'))
                info.CompressedData = true;
            else
                info.CompressedData = false;
            end
        case 'TransformMatrix'
            if (info.NDims == 2)
                A = sscanf(line, 'TransformMatrix = %f %f %f %f');
                info.TransformMatrix = reshape(A, 2, 2);
            elseif (info.NDims == 3)
                A = sscanf(line, 'TransformMatrix = %f %f %f %f %f %f %f %f %f');
                info.TransformMatrix = reshape(A, 3, 3);
            end
        case 'Offset'
            if (info.NDims == 2)
                A = sscanf(line, 'Offset = %f %f');
                info.Offset = A;
            elseif (info.NDims == 3)
                A = sscanf(line, 'Offset = %f %f %f');
                info.Offset = A;
            end
        case 'CenterOfRotation'
            if (info.NDims == 2)
                A = sscanf(line, 'CenterOfRotation = %f %f');
                info.CenterOfRotation = A;
            elseif (info.NDims == 3)
                A = sscanf(line, 'CenterOfRotation = %f %f %f');
                info.CenterOfRotation = A;
            end
        case 'ElementSpacing'
            if (info.NDims == 2)
                A = sscanf(line, 'ElementSpacing = %f %f');
                info.ElementSpacing = A;
            elseif (info.NDims == 3)
                A = sscanf(line, 'ElementSpacing = %f %f %f');
                info.ElementSpacing = A;
            end
        case 'DimSize'
            if (info.NDims == 2)
                A = sscanf(line, 'DimSize = %d %d');
                info.DimSize = A;
            elseif (info.NDims == 3)
                A = sscanf(line, 'DimSize = %d %d %d');
                info.DimSize = A;
            end
        case 'AnatomicalOrientation'
            if (info.NDims == 2)
                A = sscanf(line, 'AnatomicalOrientation = %s');
                info.AnatomicalOrientation = A;
            elseif (info.NDims == 3)
                A = sscanf(line, 'AnatomicalOrientation = %s');
                info.AnatomicalOrientation = A;
            end
        case 'ElementType'
            A = sscanf(line, 'ElementType = %s');
            info.ElementType = A;

            precision = '*uchar';  % * indicates no conversion
            if (strcmpi(strtrim(info.ElementType), 'MET_USHORT'))
                precision = '*ushort';
                disp(precision);
            end
            if (strcmpi(strtrim(info.ElementType), 'MET_FLOAT'))
                precision = 'float32';
                disp(precision);
            end
            if (strcmpi(strtrim(info.ElementType), 'MET_DOUBLE'))
                precision = 'double';
                disp(precision);
            end
            if (strcmpi(strtrim(info.ElementType), 'MET_UINT'))
                precision = 'uint';
                disp(precision);
            end
        case 'ElementNumberOfChannels'
            A = sscanf(line, 'ElementNumberOfChannels = %d');
            info.ElementNumberOfChannels = A;
        case 'ElementDataFile'
            if (info.NDims == 2)
                A = sscanf(line, 'ElementDataFile = %s');
                info.ElementDataFile = A;
                siz = info.DimSize(1) * info.DimSize(2) * info.ElementNumberOfChannels;
                if (isequal(A,'LOCAL'))
                    image = fread( fid, siz, precision );
                else
                    fid2 = fopen( [direct info.ElementDataFile], 'r' );
                    image = zeros(1,0);
                    while ~feof(fid2)
                        image = [image fread( fid2, siz, precision )];
                    end
                    fclose(fid2);
                end
                for k = 1:info.ElementNumberOfChannels
                    Im(:,:,k) = reshape(image(1 : info.ElementNumberOfChannels : end), info.DimSize(1), info.DimSize(2) );
                end

            elseif (info.NDims == 3)
                A = sscanf(line, 'ElementDataFile = %s');
                info.ElementDataFile = A;
                siz = info.DimSize(1) * info.DimSize(2) * info.DimSize(3);
                if (isequal(A,'LOCAL'))
                    image = fread( fid, siz, precision );
                else
                    fid2 = fopen( [direct info.ElementDataFile], 'r' );
                    if isempty(precision)
                        precision = 'uint8';
                    end
                    image = zeros(1,0);
                    while ~feof(fid2)
                        image = [image fread( fid2, siz, precision )];
                    end
                    fclose(fid2);
                end
                info.DimSize(1);
                info.DimSize(2);
                info.DimSize(3);
                size(image);
                for k = 1:info.ElementNumberOfChannels
                   Im(:,:,:,k) = reshape(image(1 : info.ElementNumberOfChannels : end), info.DimSize(1), info.DimSize(2), info.DimSize(3) );
                end
            end
        otherwise
            type
    end
    line = fgetl(fid);
end

fclose(fid);

end
