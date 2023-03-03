% playing with SPM12
% Going to load in the 'nards data and see if I can find his face areas
% Here goes.
% vwadia Feb2021
%% Set paths

setDiskPaths 

paths.taskCodePath = [boxPath filesep 'fMRILocVarun'];

paths.taskPath = [diskPath filesep 'Localiser_Task'];

paths.spmPath = [paths.taskPath filesep 'spm12'];

addpath(paths.spmPath);
addpath(paths.taskCodePath);
addpath(genpath(paths.taskPath));

cd(paths.taskPath);
% see spm tutorial and use their GUI

% set TTL codes
setTTLCodes;

%% creating timing files to use with SPM
% Need to create files that have columnar structure, which include
% 'onset' and 'duration' for the Face condition and the Non-Face condition
% -----------------------------------------------------------------------------------------
% TTls were written to logfile using 'now*1e9' - which can be converted to datetime object
% events = importData('logFile_from_taskfolder');
% extract startTimes and endTimes
% d = datetime(startTimes(1)*1e-9, 'ConvertFrom', 'datenum') % note the multiplication by 1e-9
% d.Format = 'dd-MMMM-yyyy HH:mm:ss:SSSSSS'; % this will now give microsecond timestamps
% BUT ------------------------------------------------------------------------------
% What tf does the anchorPulseTime mean?
% it is the time since System startup...Don't think the two can be
% reconciled
% So we will assume start time to scan = beginning of first block

blockDuration = 16; % seconds
numBlocks = 32; % blocks in a bold run

% ------------------------------------------------------------------------
Session = 10;
% ------------------------------------------------------------------------

BODY = 2;
HAND = 3;
FRUIT = 4;
GADGET = 5;
SCRAMBLED = 6;

if Session ~= 6
    FACE = 1;   
else
    FACE = 7;    
end

% load in logFile from task - BGSession1
if Session == 1
    events = importdata([paths.taskCodePath filesep 'logs' filesep 'BernardGomes_19Feb2021_2_fMRILoc_2021-02-19_10-24-41.txt']);
    taskStruct = load([paths.taskCodePath filesep 'data' filesep 'BernardGomes_19Feb2021_2_Sub_16_Block.mat']);
    fullBlockOrder = [taskStruct.blockOrder taskStruct.blockOrder]';
    numRuns = 1;

    % note that these need to be converted
    imageOnStamps = events(find(events(:, 2) == IMAGE_ON), 1)*1e-9; % dividing by a billion to undo conversion in 'writetoLog.m'
    imageOffStamps = events(find(events(:, 2) == IMAGE_OFF), 1)*1e-9;
    blockOnStamps = imageOnStamps(1:blockDuration:end);
    pulseOnStamps = blockOnStamps(1);
elseif Session == 2
    % load in logFile from task - BGSession2
    events = importdata([paths.taskCodePath filesep 'logs' filesep 'BG_6RunsTsaoLoc_4March_Att3_fMRILoc_2021-03-04_15-41-25.txt']);
    taskStruct = load([paths.taskCodePath filesep 'data' filesep 'BG_6RunsTsaoLoc_4March_Att3_Sub_32_Block.mat']);
   
    fullBlockOrder = taskStruct.blockOrder';
    numRuns = 6;
    blockOnStamps = events(find(events(:, 2) == BLOCK_ON), 1)*1e-9;
    pulseOnStamps = events(find(events(:, 2) == 100), 1)*1e-9;
elseif Session == 3
    events = importdata([paths.taskCodePath filesep 'logs' filesep 'P73CS_1_4Run_fMRILoc_2021-03-10_12-30-04.txt']);
    taskStruct = load([paths.taskCodePath filesep 'data' filesep 'P73CS_1_4Run_Sub_32_Block.mat']);

    fullBlockOrder = taskStruct.blockOrder';
    % patient tapped out after 3 runs - run #3 is missing the last 70 TRs
    % the last 70 TRs is 57s, so the scan is missing the last 4 blocks FSGS
    % in run 3
    % When trying to realign the motion is really bad in run 3 so just cut
    % it out
    numRuns = 2; 
    blockOnStamps = events(find(events(:, 2) == BLOCK_ON), 1)*1e-9;
    blockOnStamps = blockOnStamps(1:numRuns*numBlocks);
    pulseOnStamps = events(find(events(:, 2) == 100), 1)*1e-9;
    pulseOnStamps = pulseOnStamps(1:numRuns);
elseif Session == 4 % HC passive
    filename = [paths.taskCodePath filesep 'logs' filesep 'HCPassive_1_fMRILoc_2021-06-15_12-03-11.txt'];
    logfile = readtable(filename, 'ReadVariableNames', false);
    events = table2cell(logfile);
    events = cell2mat(events(:, 1:2));
    taskStruct = load([paths.taskCodePath filesep 'data' filesep 'HCPassive_1_Sub_32_Block.mat']);
   
    fullBlockOrder = taskStruct.blockOrder';
    numRuns = 3;
    blockOnStamps = events(find(events(:, 2) == BLOCK_ON), 1)*1e-9;
    pulseOnStamps = events(find(events(:, 2) == MRI_PULSE), 1)*1e-9;
elseif Session == 5 % HC active
    filename = [paths.taskCodePath filesep 'logs' filesep 'HCActive_1_fMRILoc_2021-06-15_12-35-23.txt'];
    logfile = readtable(filename, 'ReadVariableNames', false);
    events = table2cell(logfile);
    events = cell2mat(events(:, 1:2));
    numRuns = 1;
    taskStruct = load([paths.taskCodePath filesep 'data' filesep 'HCActive_1_Sub_32_Block.mat']);
   
    fullBlockOrder = taskStruct.blockOrder';
    
    blockOnStamps = events(find(events(:, 2) == BLOCK_ON), 1)*1e-9;
    pulseOnStamps = events(find(events(:, 2) == MRI_PULSE), 1)*1e-9;
elseif Session == 6 % HC Lauren
    filename = [paths.taskCodePath filesep 'logs' filesep 'HCActiveColor_fMRILoc_2021-06-15_12-45-42.txt'];
    logfile = readtable(filename, 'ReadVariableNames', false);
    events = table2cell(logfile);
    events = cell2mat(events(:, 1:2));
    taskStruct = load([paths.taskCodePath filesep 'data' filesep 'HCActiveColor_Sub_32_Block.mat']);
   
    fullBlockOrder = taskStruct.blockOrder';
    numRuns = 1;
    blockOnStamps = events(find(events(:, 2) == BLOCK_ON), 1)*1e-9;
    pulseOnStamps = events(find(events(:, 2) == MRI_PULSE), 1)*1e-9;
elseif Session == 7 % SM Passive
    filename = [paths.taskCodePath filesep 'logs' filesep 'SM_Att1_fMRILoc_2022-03-03_14-41-55.txt'];
    logfile = readtable(filename, 'ReadVariableNames', false);
    events = table2cell(logfile);
    events = cell2mat(events(:, 1:2));
    taskStruct = load([paths.taskCodePath filesep 'data' filesep 'SM_Att1_Sub_32_Block.mat']);
   
    fullBlockOrder = taskStruct.blockOrder';
    numRuns = 3;
    blockOnStamps = events(find(events(:, 2) == BLOCK_ON), 1)*1e-9;
    pulseOnStamps = events(find(events(:, 2) == MRI_PULSE), 1)*1e-9;
elseif Session == 8 % P79 Passive
    filename = [paths.taskCodePath filesep 'logs' filesep 'P79_Att1_fMRILoc_2022-03-09_09-33-26.txt'];
    logfile = readtable(filename, 'ReadVariableNames', false);
    events = table2cell(logfile);
    events = cell2mat(events(:, 1:2));
    taskStruct = load([paths.taskCodePath filesep 'data' filesep 'P79_Att1_Sub_32_Block.mat']);
   
    fullBlockOrder = taskStruct.blockOrder';
    numRuns = 3;
    blockOnStamps = events(find(events(:, 2) == BLOCK_ON), 1)*1e-9;
    pulseOnStamps = events(find(events(:, 2) == MRI_PULSE), 1)*1e-9;
elseif Session == 9 %P80 Passive
    filename = [paths.taskCodePath filesep 'logs' filesep 'P80CS_1_fMRILoc_2022-07-20_12-48-22.txt'];
    logfile = readtable(filename, 'ReadVariableNames', false);
    events = table2cell(logfile);
    events = cell2mat(events(:, 1:2));
    taskStruct = load([paths.taskCodePath filesep 'data' filesep 'P80CS_1_Sub_32_Block.mat']);
   
    fullBlockOrder = taskStruct.blockOrder';
    numRuns = 3;
    blockOnStamps = events(find(events(:, 2) == BLOCK_ON), 1)*1e-9;
    pulseOnStamps = events(find(events(:, 2) == MRI_PULSE), 1)*1e-9;
elseif Session == 10 %P82 Passive
    filename = [paths.taskCodePath filesep 'logs' filesep 'P82CS_1_fMRILoc_2022-12-14_09-16-51.txt'];
    logfile = readtable(filename, 'ReadVariableNames', false);
    events = table2cell(logfile);
    events = cell2mat(events(:, 1:2));
    taskStruct = load([paths.taskCodePath filesep 'data' filesep 'P82CS_1_Sub_32_Block.mat']);
   
    fullBlockOrder = taskStruct.blockOrder';
    numRuns = 3;
    blockOnStamps = events(find(events(:, 2) == BLOCK_ON), 1)*1e-9;
    pulseOnStamps = events(find(events(:, 2) == MRI_PULSE), 1)*1e-9;
end

%% convert to useful information

d = datetime(blockOnStamps, 'ConvertFrom', 'datenum');
d.Format = 'dd-MMMM-yyyy HH:mm:ss:SSSS';
[hON, mON, sON] = hms(d);

% now adjust for minutes/hours to get absolute timestamps
% hON = hON - min(hON);
% mON = mON - min(mON); % doing this for the minutes screws your timing up
% when you have many sessions
blockONTimes = (hON*3600)+(mON*60)+sON;
blockONTimes = reshape(blockONTimes, [numBlocks, numRuns]);

d2 = datetime(pulseOnStamps, 'ConvertFrom', 'datenum');
d2.Format = 'dd-MMMM-yyyy HH:mm:ss:SSSS';
[hOFF, mOFF, sOFF] = hms(d2);

% now adjust for minutes/hours 
% hOFF = hOFF - min(hOFF);
% mOFF = mOFF - min(mOFF);
pulseONTimes = (hOFF*3600)+(mOFF*60)+sOFF;

% zero everything (make the first pulse time start at 0)
blockONTimes = blockONTimes - pulseONTimes(1);
pulseONTimes = pulseONTimes - pulseONTimes(1);

for i = 1:size(blockONTimes, 2)
    blockONTimes(:, i) = blockONTimes(:, i) - pulseONTimes(i);
end

timingFile = [blockONTimes fullBlockOrder];

% important ones used often
Face_blocks = timingFile(find(timingFile(:, numRuns+1) == FACE), 1:numRuns);
Face_blocks = floor(Face_blocks);
AllScrambled_blocks = timingFile(find(timingFile(:, numRuns+1) == 6), 1:numRuns);
AllScrambled_blocks = floor(AllScrambled_blocks);
NonFace_blocks = timingFile(~ismember(timingFile(:, numRuns+1), [FACE, SCRAMBLED]), 1:numRuns);
NonFace_blocks = floor(NonFace_blocks);

% others
Scrambled_blocks_AfterFace = timingFile(find(timingFile(:, numRuns+1) == FACE)+1, 1:numRuns); % the scambled blocks right after the faces
Scrambled_blocks_AfterNonFace = timingFile(circshift(~ismember(timingFile(:, numRuns+1), [FACE, SCRAMBLED]), 1), 1:numRuns);
Body_blocks = timingFile(find(timingFile(:, numRuns+1) == BODY), 1:numRuns);
Hand_blocks = timingFile(find(timingFile(:, numRuns+1) == HAND), 1:numRuns);
Fruit_blocks = timingFile(find(timingFile(:, numRuns+1) == FRUIT), 1:numRuns);
Gadget_blocks = timingFile(find(timingFile(:, numRuns+1) == GADGET), 1:numRuns);
