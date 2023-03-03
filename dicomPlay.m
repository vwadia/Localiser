
% Script to mess around with dicoms
%     Write out individual frames
%     Read in tags and examine
%     Write out new images with different tags
% vwadia Jan2023

setDiskPaths
basePath = [diskPath filesep 'Localiser_Task']; 

%% Writing out frames using dicomread and dicomwrite - doesn't really work (ROSA can't see these)

% SOP = '1.2.840.10008.5.1.4.1.1.4.1'; % Enhanced MR Image Storage - Doesn't work yet because you need to specify SharedFunctionalGroupSequence
SOP = '1.2.840.10008.5.1.4.1.1.4'; % MR Image Storage

patientID = 'P80CS'; 
dicomPath = [basePath filesep patientID filesep  'Runs 1 2 and 3' filesep '790871b1-e91a-4b_002_t1_space_sag_cs4_iso_20220720'];
fileName = 'Face_NonFace_Overlay_P80CS';


% patientID = 'P79CS'; 
% dicomPath = [basePath filesep patientID filesep  'Runs12and3' filesep '75f00a82-b188-48_2001_t1_space_sag_cs4_iso_20220309'];
% fileName = 'Face_NonFace_Overlay_P79CS';


% wehy is the overlay series so much clearer for these (i.e. the images seen via imshow)?
% patientID = 'P73CS'; 
% dicomPath = [basePath filesep patientID filesep 'OverlaysAndDicoms' filesep 'dicoms'];
% fileName = 'uwcor_t1_wFE_uwt1_overlay';


outPath = [basePath filesep patientID filesep 'OverlaySeries'];
if ~exist(outPath)
    mkdir(outPath)
end

% grabbing position and orientation data - see last cell for exp
info = dicominfo([dicomPath filesep fileName]);
pffgs = struct2cell(info.PerFrameFunctionalGroupsSequence);
sfgs = struct2cell(info.SharedFunctionalGroupsSequence);

posDat = [];
orientDat = sfgs{1}.PlaneOrientationSequence.Item_1.ImageOrientationPatient';
slSp = [];
for sl = 1:length(pffgs)
    
    posDat(sl, :) = pffgs{sl}.PlanePositionSequence.Item_1.ImagePositionPatient';
    
    slSp(sl) = cross(orientDat(1:3), orientDat(4:6))*posDat(sl, :)';
    
end
sliceSpacing = abs(unique(diff(slSp))); % space between slices


info.(dicomlookup('0010', '0010')) = patientID; % patient name
info.(dicomlookup('0010', '0020')) = patientID; % patient id
info.(dicomlookup('0018', '5100')) = 'HFS'; % patient position - head first supine. you can read this value off the dicoms that come directly from the scanner
% info.(dicomlookup('0018', '0088')) = 2.4; % spacing between slices

assert(isequal(length(pffgs), info.NumberOfFrames), 'WARNING: Number of frames is inconsistent');

for fr = 1:info.NumberOfFrames
    
    InStackPosNum = pffgs{fr, 1}.FrameContentSequence.Item_1.InStackPositionNumber; % redundancy to ensure all frames are in correct order
    
    file = dicomread([dicomPath filesep fileName], "frames", fr);
    info.(dicomlookup('0020', '0032')) = posDat(fr, :)'; % make sure position data for each frame is correct.

    dicomwrite(file, [outPath filesep 'FnF_Frame_' sprintf('%03d', InStackPosNum)], info, 'CreateMode', 'Copy');
    
end

% dicomdisp([dicomPath filesep fileName '.dcm'])
% SharedFunctionalGroupsSequence

infoFrame = dicominfo([outPath filesep 'FnF_Frame_025']);

%% angle between 2 vectors

u = cross(orientDat(1:3), orientDat(4:6));
v = [0 0 2]; % diff(posDat)

CosTheta = max(min(dot(u,v)/(norm(u)*norm(v)),1),-1);
ThetaInDegrees = real(acosd(CosTheta));

%% reading the tag values - overlay file

dicomPath = [basePath filesep patientID];% filesep  'Runs 1 2 and 3' filesep '790871b1-e91a-4b_002_t1_space_sag_cs4_iso_20220720'];

fileName = 'FaceNonFaceOverlayP80CS.dcm';
fname = [dicomPath filesep fileName];

tags = ReadDicomElementList([dicomPath filesep fileName]); % in the overlay image it doesn't capture the individual frames in the way pydicom does. 

% pixData = tags(end); % pixel data saved as a single longass vector

%% reading the tag values - series (that was produced above)


patientID = 'P80CS'; 

dicomPath = [basePath filesep patientID filesep 'OverlaySeries'];

files = Utilities.readInFiles(dicomPath);

% all the slices have TONS of garbage tags for 'commandgrouplength'...why?
% and PixelData is empty in all of them...info is 'Type Included' instead
% of 'Type Dictionary' and 'explicit' = 1 instead of 0
for i = 1:length(files)
    tags = ReadDicomElementList([files(i).folder filesep files(i).name]);
    keyboard
end

%% reading the tag vales - file that works

patientID = 'ROSA_Test'; 
dicomPath = [basePath filesep patientID];

files = Utilities.readInFiles(dicomPath);

% there are 2 instances of PixelData in the preop MRI - but second is the one
% the functional from the scanner doesn't have 'pixelData' but the  values are stored in 'Private_...' ??
for i = 3:length(files)
%     tags = ReadDicomElementList([files(i).folder filesep files(i).name]);
    infoRaw = dicominfo([files(i).folder filesep files(i).name]);
    keyboard
end


%% Checking slice location for raw dicoms that work (eg. preop MRI) 

patientID = 'ROSA_Test'; 
dicomPath = [basePath filesep patientID];

files = Utilities.readInFiles(dicomPath);

files = files(1:2); 
i = 1;

% dicominfo for functional
infoRaw = dicominfo([files(i).folder filesep files(i).name]);
positionData = [];


%  - Gives a cell array of structs (1 for each slice) that each contain image position data
%  - See here for beautiful explanation of how to compute distance between slices
%  - https://groups.google.com/g/comp.protocols.dicom/c/lEp7NmiHIT0/m/taRvU-O8DwAJ
%  - In short, take orientation data (stored as a 6 element vector [row_x
%  row_y row_z col_x col_y col_z], project the position data for the
%  slice onto the cross product of the orientation vectors and then take diff(result)
 
fds = struct2cell(infoRaw.PerFrameFunctionalGroupsSequence);

% grab position and orientation data
for sl = 1:length(fieldnames(infoRaw.PerFrameFunctionalGroupsSequence))
        
    positionData(sl, :) = fds{sl}.PlanePositionSequence.Item_1.ImagePositionPatient;
    orientationData(sl, :) = fds{sl}.PlaneOrientationSequence.Item_1.ImageOrientationPatient';
    
end

oDat = orientationData(1, :); % all are the same so just keep 1

pd = [];
% project each slice position (position of top left corner voxel/pixel) onto cross product of orientation vectors (see link if confused) 
for i = 1:length(positionData)   
    pd(i) = cross(oDat(1:3), oDat(4:6))*positionData(i, :)';
end

% unique(diff(pd)) - is spacing between slices 
