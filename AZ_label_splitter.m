% divide mha label sets into individual, cropped, blob-segmented ROIs/masks
% Adam Zimmerman 2020

% To-do:
% make thresholding and erosion bulletproof or at least user-optimizable
% make script into function(s)/modularize
% generalize even more
% add interpolate:
    % [ny,nx,nz] = size(mask);
    % [y,x,z] = ndgrid(1:ny,1:nx,1:nz);
    % [Y,X,Z] = ndgrid(1:ny,1:nx,1:1/zAniso:nz);
    % imask = interp3(x,y,z,double(mask),X,Y,Z,'nearest');
clear global
clearvars
clc  % raw data file management:
cd 'C:\Users\amc39\Google Drive\ABC\Vignesh_SP\'; 
rawFds = fileDatastore('Raw*', 'ReadFcn', @importdata);
rawFullNames = rawFds.Files; % get raw names, e.g. Raw_ROI1.mha, Raw_ROI2.mha
nRaw = size(rawFullNames, 1);
rawMatrix = []; % hard to preallocate array b/c of unknown n of raw files
for raw = 1:nRaw
    fullName = rawFullNames(raw);
    [rawRt, raw_name, ext] = fileparts(fullName{1});
    [rawVolume,vol_info] = ReadData3D(rawFullNames{raw}); % import volume data
    rawMatrix{raw} = rawVolume; % assign volume to array 
end
rawReport = sprintf('%d raw file(s) found.', nRaw); disp(rawReport);

%% sets -> labels -> segmented masks
fds = fileDatastore('*Seeded.mha', 'ReadFcn', @importdata); % get all label sets
fullFileNames = fds.Files; % get set names, e.g. ROI1.mha, ROI2.mha...
nSet = size(fullFileNames, 1); % loop through all label sets
if nSet ~= nRaw % validate and report label files match raw files
    countError = 'Number of raw files does not match number of label sets'
    disp(countError);
else 
    labelReport = sprintf('%d set(s) of labels found.', nSet); disp(labelReport);
end
dKr = 50; % <<<< set dilation kernal size for dilation <<<<
eKr = 3; % <<<< set erosion kernal for erosion <<<<
thresh = 56; % <<<< set threshold for object of intrest (Vignesh's memb =< 58)
for set = 1:nSet % split label sets
    fullName = fullFileNames(set);
    [rt, name, ext] = fileparts(fullName{1});
    [volume,vol_info] = ReadData3D(fullFileNames{set}); % import label volume
    [label_matrix, label_count] = bwlabeln(volume, 26); % get 26-conn objects
    rawReport = sprintf('%d labels found in %s', label_count, name);
    disp(rawReport);
    for label = 1:label_count % w/n label set, dilate, crop, erode, save masks
        progress = sprintf('Processing mask %d:',label); disp(progress);
        tic
        mask = label_matrix == label; % make full size volume of just 1 label
        se = strel('sphere',dKr); % dilation
        dilated_mask = imdilate(mask,se);
        center = regionprops3(dilated_mask, 'centroid'); % prep for crop
        mask = dilated_mask;
        toc
        tic
%         % for debugging:
%         [mask,vol_info] = ReadData3D('C:\Users\amc39\Google Drive\ABC\Vignesh_SP\test0_ROI1_10x10x10bin_200kHz_align_inv_Seeded_label_1.mha'); % import label volume
%         
        % combine with raw data, and then crop the result.
        % this should be equivalently performant as cropping separately first.
        raw = rawMatrix{set}; % introduce corresponding raw data
        toc
        tic
        idx = find(mask); % log nonzero voxels 
        [ny,nx,nz] = size(mask); % get crop size
        [yi,xi,zi] = ind2sub([ny,nx,nz], idx); % get crop origin. Result is 1 pt
        b = 5; % boundary buffer of pixels for cropping
        xa = max(min(xi)-b,1):min(max(xi)+b,nx); 
        ya = max(min(yi)-b,1):min(max(yi)+b,ny);
        za = max(min(zi)-b,1):min(max(zi)+b,nz);
        rawSmall = raw(ya,xa,za);
        croppedMask = mask(ya,xa,za); % crop
        croppedMask = rawSmall .* logical(croppedMask); % combine
        toc
        tic
        % threshold - not lining up properly
        %smallMask(smallMask<thresh) = 0;
        %smallMask =logical(smallMask);
%         
% %                % erode
%         CC = bwconncomp(croppedMask, 26); %survey the volume for connected components
%         % discard small components (assumed to be noise or debris on glass slide)
%         csize = cellfun(@numel, CC.PixelIdxList); % size of all objects in voxels
%         idx = csize>=500; % <<<<<<<<<<<<<<<<<<< EXPERIMENT WITH THIS
%         CC.NumObjects = sum(idx);
%         CC.PixelIdxList = CC.PixelIdxList(idx);
%         mask = croppedMask(CC)~=0;
%         mask = imerode(mask, eKr); % erode
%         newim_2 = zeros(size(mask),'uint8'); % reinitialize raw data
%         newim_2(mask) = im(mask); % set everything outside the mask to zero
%         tic
%         fn_newim_2 = [rt filesep p.AnalysisPath filesep 'segCh3_' 'ekr' num2str(p.ekr) '_dkrbb' num2str(p.dkr_bb) '_dkrc' num2str(p.dkr_c) '_min_P_bb' num2str(p.min_P_bb) '_max_p_bk' num2str(p.max_p_bk) '_minBBsize' num2str(p.minBBsize) '_' fn_probabilities];
%         % writetiff(newim_2, fn_newim_2);
%  
%        
        %suffix = ['se_' dKr '_label_' label]; % buggy
        mhaWriter(['test1_', name, sprintf('_label_%d',label), ext], croppedMask, [1,1,1], 'uint8'); % save
        toc          
    end
end

%%
    
%     % if cropping and eroding existing files
% fds2 = fileDatastore('test*', 'ReadFcn', @importdata); % grab all label sets
% fullFileNames = fds2.Files; % get set names, e.g. ROI1.mha, ROI2.mha...
% blobCount = size(fullFileNames, 1); % loop through several sets
% se2 = strel('sphere',3)

%     for blob = 1:blobCount % Count % NOTE ME <<<<<<<<<<<<<<<<<
%         fullName = fullFileNames(blob);
%         [rt, name, ext] = fileparts(fullName{1}); % set name and ext
%         [volume,vol_info] = ReadData3D(fullFileNames{blob}); % import volume data
%         report = sprintf('%d labels found in %s', blobCount, rt); disp(report);
%     end
    %     % erode
    %     CC = bwconncomp(Vout, 26); %survey the volume for connected components
    %     % discard small components (assumed to be noise or debris on glass slide)
    %     csize = cellfun(@numel, CC.PixelIdxList); % size of all objects in voxels
    %     idx = csize>=500; % <<<<<<<<<<<<<<<<<<< EXPERIMENT WITH THIS
    %     CC.NumObjects = sum(idx);
    %     CC.PixelIdxList = CC.PixelIdxList(idx);
    %     mask = labelmatrix(CC)~=0;
    %     mask = imdilate(mask, se2); % dilate to connect disconnected objects from earlier erosion
    %     newim_2 = zeros(size(im),'uint8'); % reinitialize raw data
    %     newim_2(mask) = im(mask); % set everything outside the mask to zero
    %     tic
    %     fn_newim_2 = [rt filesep p.AnalysisPath filesep 'segCh3_' 'ekr' num2str(p.ekr) '_dkrbb' num2str(p.dkr_bb) '_dkrc' num2str(p.dkr_c) '_min_P_bb' num2str(p.min_P_bb) '_max_p_bk' num2str(p.max_p_bk) '_minBBsize' num2str(p.minBBsize) '_' fn_probabilities];
    %     % writetiff(newim_2, fn_newim_2);
    %     mhaWriter(['test_erode_', name, sprintf('_%d',blob), ext], Vout, [1,1,1], 'uint8'); % save
    %     toc
    % end 
