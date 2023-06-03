% Script to convert segmentation files from Slicers into format ROSA likes

%% Set paths

setDiskPaths
basePath = [diskPath filesep 'Localiser_Task'];

% patientID = 'P82CS'; 
% dicomPath = [basePath filesep patientID filesep 'Runs12and3'];

patientID = 'P84CS'; 
dicomPath = [basePath filesep patientID filesep 'OverlayImagesMango'];

% fileName = ['p84cs_T1w_wThal_Overlay']; % for Natasha
fileName = ['rtss_1.2.826.0.1.3680043.8.274.1.1.0.5449.1679956410.32184'];
% fileName = ['image0000_1.2.826.0.1.3680043.8.274.1.1.0.5449.1679956410.32185'];
% fileName = ['Face_NonFace_Overlay_P84CS']
% fileName = ['FnF_Frame_001']

outPath = [dicomPath filesep 'OverlaySeries_' fileName];
% if ~exist(outPath)
%     mkdir(outPath)
% end



%% Adding tags manually - so far hasn't worked 

% read in dicom information
info = dicominfo([dicomPath filesep fileName]);

% read in contour info
contours = dicomContours(info);
 

% re-write the modality and some other fields
info.(dicomlookup('0010', '0010')) = patientID; % patient name
info.(dicomlookup('0010', '0020')) = patientID; % patient id
info.(dicomlookup('0008', '0060')) = 'CT'; % modality



info.(dicomlookup('0028', '0010')) = 256;
info.(dicomlookup('0028', '0011')) = 256;
info.(dicomlookup('0028', '1050')) = 40;
info.(dicomlookup('0028', '1051')) = 400;
info.(dicomlookup('0020', '0037')) = [1; 0; 0; 0; 0; -1];
info.(dicomlookup('0020', '0032')) = [-1.315562130000000e+02;1.319996950000000e+02;95.379791000000000];
info.(dicomlookup('0028', '0030')) = [1;1];
info.(dicomlookup('0018', '0050')) = 1;
info.(dicomlookup('0028', '0004')) = 'MONOCHROME2'; % Photometric interpretation
% info.(dicomlookup('0008', '9205')) = 'MONOCHROME'; % PixelPresentation - for enhanced MR/CT images
info.(dicomlookup('0008', '0016')) = '1.2.840.10008.5.1.4.1.1.2'; % SOPCLassUID CT
info.(dicomlookup('0002', '0002')) = '1.2.840.10008.5.1.4.1.1.2'; % MediaStorageSOPCLassUID CT
% 1.2.840.10008.5.1.4.1.1.481.3 - contour files


% convert contour information to DICOM metadata
info = convertToInfo(contours);

% write out contour file as a dicom
dicomwrite([], [dicomPath filesep fileName '_convToDic.dcm'], info, 'CreateMode', 'Copy');


%% ROSA Wants the following tags

% Rows (0028, 0010) - 256
% Columns (0028, 0011) - 256
% WindowCenter (0028, 1050) - 40
% WindowWidth (0028, 1051) - 400
% ImagePositionPatient (0020, 0032) - [-1.315562130000000e+02;1.319996950000000e+02;95.379791000000000]
% ImageOrientationPatient (0020, 0037) - [1; 0; 0; 0; 0; -1]
% Pixel Spacing (0028, 0030) - [1;1]
% Thickness (0018, 0050)
% 
% Says non-grayscale images aren't supported




