
% Cleaned up script to convert a mango overlay image into 
% dicom folder for ROSA


% link that explains what needs to be computed to properly check spacing between slices 
% also outlines what ImagePatientPosition and ImagePatientOrientation
% actually mean
% https://groups.google.com/g/comp.protocols.dicom/c/lEp7NmiHIT0/m/taRvU-O8DwAJ
% full text is in the last cell (in case link expires)

% vwadia/2023

%% Set paths

setDiskPaths
basePath = [diskPath filesep 'Localiser_Task'];

% patientID = 'P82CS'; 
% dicomPath = [basePath filesep patientID filesep 'Runs12and3'];

% patientID = 'P84CS'; 
% dicomPath = [basePath filesep patientID filesep 'OverlayImagesMango'];

% patientID = 'P85CS'; 
% dicomPath = [basePath filesep patientID filesep 'OverlayImagesMango'];

patientID = 'P86CS'; 
dicomPath = [basePath filesep patientID filesep 'Runs1and2_Only' filesep 'OverlayImagesMango'];


% % fileName = ['p84cs_T1w_wFullThal_Overlay']; % for Natasha
% fileName = ['p84cs_T1w_wCMThal_Overlay']; % for Natasha

fileName = ['Face_NonFace_Overlay_' patientID];
% fileName = ['Face_Everything_Overlay_' patientID];




outPath = [dicomPath filesep 'OverlaySeries_' fileName];
if ~exist(outPath)
    mkdir(outPath)
end



%% read in the relevant tags that ROSA wants

% dicom info
info = dicominfo([dicomPath filesep fileName]);

% position data is stored here
pffgs = struct2cell(info.PerFrameFunctionalGroupsSequence);

% orientation data 
sfgs = struct2cell(info.SharedFunctionalGroupsSequence);

posDat = [];
slSp = [];
orientDat = sfgs{1}.PlaneOrientationSequence.Item_1.ImageOrientationPatient';

for sl = 1:length(pffgs)
    
    % read in ImagePatientPosition for each frame
    posDat(sl, :) = pffgs{sl}.PlanePositionSequence.Item_1.ImagePositionPatient';
    
    % compute the distance between slices by projecting position data onto
    % cross product of orientation vectors
    slSp(sl) = cross(orientDat(1:3), orientDat(4:6))*posDat(sl, :)';
    
end
sliceSpacing = abs(unique(diff(slSp))); % space between slices - mainly for visual inspection

%% change tag values in the written out files 

info.(dicomlookup('0010', '0010')) = patientID; % patient name
info.(dicomlookup('0010', '0020')) = patientID; % patient id
info.(dicomlookup('0018', '5100')) = 'HFS'; % patient position - head first supine. you can read this value off the dicoms that come directly from the scanner

% is the number of frames correct?
assert(isequal(length(pffgs), info.NumberOfFrames), 'WARNING: Number of frames is inconsistent');

tic
for fr = 1:info.NumberOfFrames
    
    % redundancy to ensure all frames are in correct order
    InStackPosNum = pffgs{fr, 1}.FrameContentSequence.Item_1.InStackPositionNumber; 
    
    % read in frame from overlay image
    file = dicomread([dicomPath filesep fileName], "frames", fr);
    
    % make sure position data for each frame is correct.
    info.(dicomlookup('0020', '0032')) = posDat(fr, :)'; 
    
    % write out frame as a new dicom - copying over all the unchanged
    % values from the overlay image 
%     dicomwrite(file, [outPath filesep 'FnF_Frame_' sprintf('%03d', InStackPosNum)], info, 'CreateMode', 'Copy');
    dicomwrite(file, [outPath filesep 'Frame_' sprintf('%03d', InStackPosNum)], info, 'CreateMode', 'Copy');
    
end
toc

%% helpful background


% In brief, you have a stack of slices, all slices are parallel to each other - like a deck of cards. The deck (slices) can be organized in a cuboid fashion as is typical in MR and PET (like cards in a card box) 
% or gantry tilted (like a card deck that you slant with your finger) as is sometimes used in CT.
% 
% Either way, for volumetrics, you want the distance from slice center to slice center so that you can calculate the voxel volume as: interslice-distance X pixelspacingX X pixelSpacingY.
% Each slice has a corner coordinate available in the ImagePositionPatient DICOM field. You could use this directly to calculate inter-slice distance as long as you don't have gantry tilt 
% and you know how the slices are ordered so that you know how to get the distance from neighboring slices. For gantry tilt, the card deck analogy should convince you quickly that the corner-to-corner 
% distance is now longer than the perpendicular slice distance (which is the one you want).
% 
% A more general way of calculating the interslice distance is to project each slice corner onto a vector that runs perpendicular to your slices. 
% Following the card deck analogy, that is like poking a needle straight through the deck and making little (very little) marks on the needle for each card. 
% Each mark you made should now be 0.01mm apart from the next if your card thickness is 0.01mm. You can intuitively appreciate that this is also true for a slanted (tilted) deck.
% 
% To get that perpendicular vector you need to do some math since it is not directly listed in the DICOM header. 
% Fortunately it is very easy to calculate as you have the row and column vectors (in the IOP field) of the DICOM and the perpendicular vector is just the cross-product of those vectors. 
% The row and column vectors describe the direction of your rows (image left right) and columns (up down) in the scanners coordinate system. So the final step is now to project each of the slice corners (IPP) onto the 
% IOP and sort them to make sure they are in order.
% That is basically it.
% 
% There's some code here: https://github.com/horosproject/horosplugins/blob/767f630607094e3ba3b814f788fc49736c70367d/VoxelVolume/VoxelVolumeFilter.m

