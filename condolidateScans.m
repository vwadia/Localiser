% Script to consolidate the functional scans when they are sometimes stored in separate folders.
% I manually created folders called 'run1', 'run2' etc. and dumped all the relevant image folders into those.
% Then I change the 'homeDir' variable to the relevant run folder and run
% this script.
% run this from within the patient folder
% vwadia March 7th 2022

for i = 1:3
    
% homeDir = [pwd filesep 'Functionals' filesep 'run3'];
homeDir = [pwd filesep 'Functionals' filesep 'run' num2str(i)]

if strcmp(homeDir, [pwd filesep 'Functionals' filesep 'run1'])
    outDir = [pwd filesep 'addd69d5-9c54-4a_9001_ep2d_bold_moco_sms6_AP_20230515']; 
elseif strcmp(homeDir, [pwd filesep 'Functionals' filesep 'run2'])
%     outDir = [pwd filesep 'Runs2and3_Only' filesep '75f00a82-b188-48_9001_ep2d_bold_moco_sms6_AP_1_20220309'];
    outDir = [pwd filesep 'addd69d5-9c54-4a_11001_ep2d_bold_moco_sms6_AP_2_20230515'];
elseif strcmp(homeDir, [pwd filesep 'Functionals' filesep 'run3'])
%     outDir = [pwd filesep 'Runs2and3_Only' filesep '75f00a82-b188-48_10001_ep2d_bold_moco_sms6_AP_1_20220309'];
    outDir = [pwd filesep 'addd69d5-9c54-4a_13001_ep2d_bold_moco_sms6_AP_3_20230515'];
end

if ~exist(outDir)
    mkdir(outDir);
end

% foldDir = dir(homeDir);
% foldDir = foldDir(~ismember({foldDir.name}, {'.', '..', '.DS_Store', 'Thumbs.db'}));
foldDir = Utilities.readInFiles(homeDir);

for f = 1:length(foldDir)
    
%     imDir = dir([foldDir(f).folder filesep foldDir(f).name]);
%     imDir = imDir(~ismember({imDir.name}, {'.', '..', '.DS_Store', 'Thumbs.db', '*.txt'}));
    im = dir(fullfile([foldDir(f).folder filesep foldDir(f).name], '*.nii'));
%     copyfile([im.folder filesep im.name], [homeDir filesep im.name]);
    copyfile([im.folder filesep im.name], [outDir filesep im.name]);


    
end
end