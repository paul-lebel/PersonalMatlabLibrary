
% Declare global variables for use in callback functions
% global AndorTime
% global AndorFrameIndex
% global AndorImages
% global AndorPeriod
% global callback_cmosFramesAcquired
% global andorFid

clear cropMovie

global dualFig dataFig ax1 ax2 cmosStartTime cmosFid sensorData s_main
global andorStruct sdaq1 digiStates lockInfo

% Sets the acquisition loop time
cmosLoopTime = 1;
andorStruct.cmosFramesAcquired = 0;

magX = 92;
magY = 92;

% Disable previously defined vid object callbacks for background acquisition
set(vid,'TimerFcn',[]);
set(vid,'StopFcn',[]);
set(vid,'FramesAcquiredFcn',[]);

% Set up the Andor for single molecule fluorescence
setupAndorFluorescence;
SetTriggerMode(1);        %   Set trigger mode: 0 for Internal, 1 for External, 6 for External start, 7 for External Exposure ...

if exist('AndorCropVec','var')
    SetImage(1,1,AndorCropVec(1),AndorCropVec(2),AndorCropVec(3),AndorCropVec(4)); % AndorCropVec should be obtained from 'getAndorCropVec'
else
    singleFrame = returnNFrames(xsize,ysize,1,0);
    fig = figure;
    imagesc(singleFrame); getAndorCropVec;
    delete(fig);
    SetImage(1,1,1,xsize,1,ysize); % AndorCropVec should be obtained from 'getAndorCropVec'
end

AndorYsize = 1 + AndorCropVec(2) - AndorCropVec(1);
AndorXsize = 1 + AndorCropVec(4) - AndorCropVec(3);
andorStruct.dims = [AndorXsize AndorYsize];

% Set Andor frame rate
andorStruct.dt = 0.01;
SetExposureTime(andorStruct.dt*.85);
[ret,Exposure, Accumulate, Kinetic]=GetAcquisitionTimings;
AndorRate = floor(min(1/andorStruct.dt,1/Kinetic)/5)*5
andorStruct.dt = 1/AndorRate;

% Global var. used to keep track of how many Andor frames have been acquired
andorStruct.frameIndex = 1;

% Get daq info
d = daq.getDevices;
subsys = d.Subsystems;
chNames = {subsys.ChannelNames};  % Terminal names: (5x1 cell) 1: ai, 2: ao, 3: digital 4: ctrIn  5:ctrOu

% Get user data
start_path = 'F:\Paul_Data\2014\October';
dirname = uigetdir(start_path,'Select directory to save');
basefilename = input('Base file name? ','s');
% fitFlag = input('Do (quasi) realtime gaussian fitting?','s');
nCMOSFrames = input('Number of CMOS frames?');
% stackFactor = input('CMOS big frame size (enter ''1'' for no stack)?');
stackFactor = 100;
cmosFrameRate = input('CMOS frame rate? (Make sure it''s the same as in the MC control tool)');
fitFlag = input('Gaussian fitting? (y/n)','s');
% nCrops = input('Number of CMOS crops?');
nCrops = 1;
tMax = nCMOSFrames/cmosFrameRate;
nAndorImages = ceil(tMax/andorStruct.dt);

% Allocate space in a global variable for the Andor Images
andorStruct.images = uint16(zeros(AndorYsize,AndorXsize,nAndorImages));
% AndorRate = 1/andorStruct.dt;
% AndorTime = zeros(nAndorImages,1);
andorStruct.time = zeros(nAndorImages,1);

% Script containing commands to set up a daq object for the CMOS
% strobe-clobked acquisition
% setupCombinedStrobeDaq;
setupCountStrobe2;
lockInfo.daqTriggerTime = 0;

sensorData.data = zeros(s_main.Rate*tMax*2,2);
sensorData.bigInd = 0;
sensorData.litInd = 0;

% Create and open a files for the image streams
cmosFid = fopen([dirname '\' basefilename '_CMOSmovie.dat'],'w');
andorStruct.fid = fopen([dirname '\' basefilename '_Andormovie.dat'],'w');

% Create and open a file for the
sensorFid = fopen([dirname '\' basefilename '_sensorData.dat'],'w');

isStack = (stackFactor > 1);
bg = int16(takeBG(vid,100,'F:\bgFrame',stackFactor,isStack));
stop(vid);
flushdata(vid);
save([dirname '\' [basefilename '_bg.mat']],'bg');
set(getselectedsource(vid),'BuffersToUse',cmosFrameRate);

% Some CMOS details
numBigFrames = ceil(nCMOSFrames/stackFactor);
cmosFrameDims = get(vid,'VideoResolution');
cmosFrameDims(2) = cmosFrameDims(2)/stackFactor;
cmosFrameDims = fliplr(cmosFrameDims);
cmosBigFrameDims = [cmosFrameDims(1)*stackFactor, cmosFrameDims(2)];
bigFramesPerLoop = ceil(cmosLoopTime*cmosFrameRate/stackFactor);

% Get CMOS crop(s)
cmosCropSize = [13 13];
coords = prevCrop(vid,cmosFrameDims,nCrops,cmosCropSize,stackFactor);
cmosMovieBytes = nCMOSFrames*prod(cmosCropSize)*2         % Number of bytes each CMOS movie will take on disk in int16 format

% Bucket for the big frames that come straight from the camera
cmosBigImageBuffer = int16(zeros(cmosFrameDims(1)*stackFactor,cmosFrameDims(2),1,bigFramesPerLoop));

% Bucket for the restacked frames
cmosSmallFrameBuffer = int16(zeros(cmosFrameDims(1),cmosFrameDims(2),bigFramesPerLoop*stackFactor));

% Bucket for the cropped frame
cmosCropFrameBuffer = int16(zeros(cmosCropSize(1),cmosCropSize(2),bigFramesPerLoop*stackFactor));

% Variable for fitting results
stats = zeros(nCMOSFrames,6);

% Configure CMOS
set(vid,'FramesPerTrigger',nCMOSFrames/stackFactor);
set(vid,'FramesAcquiredFcn',{'triggerAndor_callback',andorStruct.dims});
set(vid,'StopFcn',@stopAndor_callback);
vid.FramesAcquiredFcnCount = round(cmosFrameRate/stackFactor); % Sets the callback rate to ~1Hz

% Cumulative indicator of frames acquired
totalAcquired = zeros(nCMOSFrames/stackFactor,1);
framesAvailable = 0;
count = 1;

% Create figures for displaying image data
dualFig = figure('Position',[50 600 700 380]);
set(dualFig,'KeyPressFcn','keep=0');
ax1 = subplot(1,2,1);
ax2 = subplot(1,2,2);
dataFig = figure('Position',[780 600 700 380]);
% angAx = subplot(2,1,1);
zAx = subplot(1,1,1);

% Prepare the Andor for acquisition
FreeInternalMemory();
PrepareAcquisition();

% Start the data acquisition object
clear -function tempLock;
s_main.Channels(4).resetCounter; s_main.Channels(3).resetCounter;
s_main.startBackground();
while lockInfo.daqTriggerTime == 0
    pause(.02);
end

% Start the CMOS acquisition and record the trigger time
start(vid); cmosStartTime = vid.InitialTriggerTime;
lockInfo.daqTriggerTime = datevec(lockInfo.daqTriggerTime);
lockInfo.cmosDaqDeltaT = etime(cmosStartTime, lockInfo.daqTriggerTime);

%   Open the shutter
SetShutter(0, 1, 50, 50);

% Start Andor
StartAcquisition();

%------------------ acquisition loop -------------------------------------
% Flag which determines continuation of the acquisition loop
keep = 1;
tloop= zeros(1E4,1);

% Start timer
tic;

% Start of the acquisition loop
while(keep)
    
    litInd = 1+(count-1)*stackFactor*bigFramesPerLoop;
    bigInd = count*stackFactor*bigFramesPerLoop;
    
    
    if strcmp(vid.Running,'off')
        break;
    end
    
    % Wait until the right number of frames have been generated
    while(get(vid,'FramesAvailable') < bigFramesPerLoop )
        pause(.0005);
    end
    
    % Turn on the green laser at fifth loop iteration (arb)
    if count == 5
        digiStates(1) = 1;
        sdaq1.outputSingleScan(digiStates);
    end
    
    % Get the CMOS data
    [cmosBigImageBuffer frametimes{count}] = getdata(vid,bigFramesPerLoop);
    
    % Chop the stack of big frames into little ones
    cmosSmallFrameBuffer = int16(ReStackFrames(cmosBigImageBuffer,cmosFrameDims,stackFactor,bigFramesPerLoop));
    cmosSmallFrameBuffer = bsxfun(@minus,cmosSmallFrameBuffer,bg);
    cmosCropFrameBuffer = cmosSmallFrameBuffer(coords(1):coords(2)-1,coords(3):coords(4)-1,:);
    
    % Write the cropped frames to disk
    fwrite(cmosFid,cmosCropFrameBuffer,'int16');
    fprintf('Wrote frames %i to %i \n',litInd,bigInd);
    
    % Image previewing------------------------------------------
    set(0,'CurrentFigure',dualFig);
    set(dualFig,'CurrentAxes',ax1);
    %     set(ax1,'CData', cmosCropFrameBuffer(:,:,end));
    if count < 5
        prevObj = imagesc(cmosCropFrameBuffer(:,:,end)); axis image;
        drawnow;
    else
        set(prevObj,'CData',cmosCropFrameBuffer(:,:,end));
    end
    
    if strcmp(fitFlag,'y')
        stats(litInd:bigInd,:) = gsolve2d(double(cmosCropFrameBuffer(:)),cmosCropSize);
        
        % Display angle data. Short circuit this operation if we are falling
        % behind on acquisition.
        if (count > 4) && ( (tloop(count-1)-tloop(count-2)) < 3*cmosLoopTime)
            %         cx = stats(1:bigInd,3)*magX;
            %         cy = stats(1:bigInd,4)*magY;
            %         [cx cy] = driftCorrect(cx,cy,1/cmosFrameRate);
            %         eStruct = fit_ellipse(cx,cy);
            %         [cx cy] = fixEllipticity(cx,cy,eStruct);
            %         angle = unwrap(atan2(cy,cx));
            set(0,'CurrentFigure',dataFig);
            %         set(dataFig,'CurrentAxes',angAx);
            % %         plot([1:bigInd]/framerate,angle(1:bigInd)/(2*pi));
            %         plot(cx,cy,'.','markersize',2); axis equal;
            set(dataFig,'CurrentAxes',zAx);
            cla;
            zTemp = -140*log(stats(1:bigInd,2).*stats(1:bigInd,5).*stats(1:bigInd,6));
            plot(zTemp(2000:end),'b');
            hold all;
            plot(zplp(zTemp(2000:end),cmosFrameRate,30),'r');
            
            drawnow;
        end
    end
    % End previewing of frame-----------------------------------
    
    % Update the total acquired indicator
    totalAcquired(count) = bigInd;
    
    % Register the time at which this loop finished
    tloop(count) = toc;
    
    if (totalAcquired(count) > nCMOSFrames)
        break;
    end
    
    count = count + 1;
    
end

clear tempLock;
SetShutter(0, 2, 50, 50);                   % Close the Andor shutter
stop(vid);                                  % Stop the CMOS vid object
s_main.stop;                                % Stop the data acquisition obj
delete(lh); clear lh;                       % Release listener for the DAQ
delete(s_main);                             % delete the DAQ object
clearvars -global s_main                    % global clear of the DAQ object

digiStates(1) = 0;
sdaq1.outputSingleScan(digiStates);

fclose(cmosFid);                            % Close the cmos raw movie binary file
fclose(andorStruct.fid);                    % Close the Andor raw movie binary file
fclose(sensorFid);                          % Close the sensor data raw binary file

set(vid,'TimerFcn',[]);
set(vid,'StopFcn',[]);
set(vid,'FramesAcquiredFcn',[]);

lastInd = find(totalAcquired>0,1,'last');
nCMOSFrames = totalAcquired(lastInd);

% stats = stats(1001:nCMOSFrames,:);

fitData.cx = stats(:,3); fitData.cy = stats(:,4);
fitData.h = stats(:,2); fitData.sx = stats(:,5); fitData.sy = stats(:,6);
fitData.I = stats(:,2).*stats(:,5).*stats(:,6);
fitData.zNoCal = subPoly(-140*log(fitData.I),0);

%
% % Make sure the number of Andor frames is consistent with the frame index
% andorStruct.frameIndex = min(andorStruct.frameIndex,size(andorStruct.images,3));
% andorStruct.images = andorStruct.images(:,:,1:andorStruct.frameIndex);

% Interpolate between nonzero entries in the 'cmosFramesAcquired' field in andorStruct
% nonzeroInds = find(andorStruct.cmosFramesAcquired > 0);
% andorStruct.cmosFramesAcquired = round(interp1(nonzeroInds,andorStruct.cmosFramesAcquired(nonzeroInds),1:andorStruct.frameIndex)*stackFactor);


aFlag = input('Analyze results? (1/0)');
if aFlag
    results = batchPostProcessNoPSD(fitData,1/cmosFrameRate);
end

%
% andorStruct.cmosFramesAcquired = andorStruct.cmosFramesAcquired(inds2);
% andorStruct.cmosTime = results.time(andorStruct.cmosFramesAcquired);

cropFlag = input('Crop Andor movies? (1/0)');
if cropFlag
    disp('Crop donor');
    donorCrop = cropMovie(andorStruct.images);
    disp('Crop Acceptor');
    acceptorCrop = cropMovie(andorStruct.images);
    donorTrace = squeeze(mean(mean(donorCrop,1),2));
    acceptorTrace = squeeze(mean(mean(acceptorCrop,1),2));
end


if cropFlag && aFlag
    % Begin post-analysis to coordinate CMOS and Andor traces
    clear acceptorSynched donorSynched zSynched
    cmosStartInd = find(abs(daqTime - lockInfo.cmosDaqDeltaT) < 2/cmosFrameRate,1,'first');
    lockInfo.data(:,3) = lockInfo.data(:,3) - lockInfo.data(cmosStartInd,3);
    posInds = find(lockInfo.data(:,3)>0 & lockInfo.data(:,3) < nCMOSFrames);
    cmosCounter = lockInfo.data(posInds,3);
    andorCounter = lockInfo.data(posInds,4);
    daqTime2 = daqTime(posInds);
    zSynched = results.zFSCorr(cmosCounter);
    firstAndorFrame = find(andorCounter > 0,1,'first');
    temp = donorTrace(andorCounter(firstAndorFrame:end));
    donorSynched(firstAndorFrame:(firstAndorFrame - 1 + numel(temp))) = temp;
    temp = acceptorTrace(andorCounter(firstAndorFrame:end));
    acceptorSynched(firstAndorFrame:(firstAndorFrame - 1 + numel(temp))) = temp;
    results.dTime = daqTime2;
    results.a = acceptorSynched;
    results.d = donorSynched;
    results.z = zSynched;
    save([dirname '\' basefilename 'results.mat'],'results');
    save([dirname '\' basefilename '_info.mat'],'cmosStartTime', 'nCMOSFrames', ...
    'stackFactor','magX','magY','Exposure','Accumulate','Kinetic', ...
    'AndorCropVec','cmosFrameRate','numBigFrames','cmosFrameDims','cmosCropSize', ...
    'fitData');
    save([dirname '\' basefilename 'andorStruct.mat'],'andorStruct');
    save([dirname '\' basefilename 'lockInfo.mat'],'lockInfo');

    
end



% inds2 = find(andorStruct.cmosFramesAcquired <= numel(results.time) &~ isnan(andorStruct.cmosFramesAcquired));
% acceptorTrace = acceptorTrace(inds2);
% donorTrace = donorTrace(inds2);
% acceptorTraceInterp = interp1(andorStruct.time',acceptorTrace,results.time,'linear',0);
% donorTraceInterp = interp1(andorStruct.time',donorTrace,results.time,'linear',0);
% [c lags] = xcorr(subPoly(results.zFSCorr,0), subPoly(-acceptorTraceInterp,0));
% maxInd = find(abs(c) == max(abs(c)));
% shift = lags(maxInd);
% aInterp2 = zeros(size(acceptorTraceInterp));
% dInterp2 = zeros(size(acceptorTraceInterp));
% aTemp = acceptorTraceInterp( (1+shift):end);
% dTemp = donorTraceInterp( (1+shift):end);
% aInterp2(1:numel(aTemp)) = aTemp;
% dInterp2(1:numel(dTemp)) = dTemp;
% results.donor = circshift(donorTraceInterp',shift);
% results.acceptor = circshift(acceptorTraceInterp',shift);
% results.FRET = trace2FRET(results.donor,results.acceptor);

% Save relevant variables


fclose('all');
