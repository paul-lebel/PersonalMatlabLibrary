
% Declare global variables for use in callback functions

global dualFig
global dataFig
global ax1 ax2
global cmosStartTime
global force_obj
global rotation_obj
global cmosFid

clear cropMovie

% Sets the acquisition loop time
cmosLoopTime = 1;
callback_cmosFramesAcquired = 0;

magX = 92;
magY = 92;

magPos = force_obj.qPOS('1');
force = hToForce_halfInch(magPos);

% Disable previously defined vid object callbacks for background acquisition
set(vid,'TimerFcn',[]);
set(vid,'StopFcn',[]);
set(vid,'FramesAcquiredFcn',[]);

% Get daq info
d = daq.getDevices;
subsys = d.Subsystems;
chNames = {subsys.ChannelNames};  % Terminal names: (5x1 cell) 1: ai, 2: ao, 3: digital 4: ctrIn  5:ctrOut

% Get user data
start_path = 'F:\Louis';
dirname = uigetdir(start_path,'Select directory to save');
basefilename = input('Base file name? ','s');
fitFlag = input('Do (quasi) realtime gaussian fitting? (0/1)');
nCMOSFrames = input('Number of CMOS frames?');
% stackFactor = input('CMOS big frame size (enter ''1'' for no stack)?');
stackFactor = 100;
cmosFrameRate = input('CMOS frame rate? (Make sure it''s the same as in the MC control tool)');
% nCrops = input('Number of CMOS crops?');
nCrops = 1;
tMax = nCMOSFrames/cmosFrameRate;


% Create and open a files for the image streams
cmosFid = fopen([dirname '\' basefilename '_CMOSmovie.dat'],'w');
% andorFid = fopen([dirname '\' basefilename '_Andormovie.dat'],'w');

% Create and open a file for the
% sensorFid = fopen([dirname '\' basefilename '_sensorData.dat'],'w');

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
cmosCropSize = [11 11];
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
set(vid,'FramesPerTrigger',2*nCMOSFrames/stackFactor);
% set(vid,'FramesAcquiredFcn',{'triggerAndor_callback',AndorFrameDims});
% set(vid,'StopFcn',@stopAndor_callback);
% vid.FramesAcquiredFcnCount = round(cmosFrameRate/stackFactor); % Sets the callback rate to ~1Hz

% Cumulative indicator of frames acquired
totalAcquired = zeros(nCMOSFrames/stackFactor,1);
framesAvailable = 0;
count = 2;

% Create figures for displaying image data
dualFig = figure('Position',[50 600 700 380]);
set(dualFig,'KeyPressFcn','keep=0');
ax1 = subplot(1,2,1);
ax2 = subplot(1,2,2);
dataFig = figure('Position',[780 600 700 380]);
 angAx = subplot(2,1,1);
%zAx = subplot(1,1,1);

% Do rotation macro here. This should halt anything that's
rotation_obj.HLT('1');
rotation_obj.MAC_START('TT_curve')
start(vid); cmosStartTime = vid.InitialTriggerTime;


%------------------ acquisition loop -------------------------------------
% Flag for acquisition loop
keep = 1;
tloop= zeros(1E4,1);

% Start timer
tic;
start_skip=5000; % number of frames to skip during analysis
while((totalAcquired(count-1) < nCMOSFrames) && (keep == 1))
    
    litInd = 1+(count-1)*stackFactor*bigFramesPerLoop;
    bigInd = count*stackFactor*bigFramesPerLoop;
    
    
    if strcmp(vid.Running,'off')
        break;
    end
    
    % Wait until the right number of frames have been generated
    while(get(vid,'FramesAvailable') < bigFramesPerLoop )
        pause(.0005);
    end
    
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
    imagesc(cmosCropFrameBuffer(:,:,end)); axis image;
    drawnow;
    
    if fitFlag
        stats(litInd:bigInd,:) = gsolve2d(double(cmosCropFrameBuffer(:)),cmosCropSize);
    end
    
    % Display angle data. Short circuit this operation if we are falling
    % behind on acquisition.
    if (count > 4) && ( (tloop(count-1)-tloop(count-2)) < 3*cmosLoopTime && fitFlag)
        bigInd
        cx = stats(start_skip+1:bigInd,3)*magX;
        cy = stats(start_skip+1:bigInd,4)*magY;
        [cx cy] = driftCorrect(cx,cy,1/cmosFrameRate);
        eStruct = fit_ellipse(cx,cy);
        [cx cy] = fixEllipticity(cx,cy,eStruct);
        angle = unwrap(atan2(cy,cx));
        set(0,'CurrentFigure',dataFig);
        %         set(dataFig,'CurrentAxes',angAx);
        % %         plot([1:bigInd]/framerate,angle(1:bigInd)/(2*pi));
        %         plot(cx,cy,'.','markersize',2); axis equal;
        set(dataFig,'CurrentAxes',angAx);
        cla;
        plot([1:bigInd-start_skip]/cmosFrameRate,angle(1:bigInd-start_skip)/(2*pi));
        
        %         zTemp = -140*log(stats(1:bigInd,2).*stats(1:bigInd,5).*stats(1:bigInd,6));
        %         plot(zTemp(2000:end),'b');
        %         hold all;
        %         plot(zplp(zTemp(2000:end),cmosFrameRate,30),'r');
        
        drawnow;
    end
    % End previewing of frame-----------------------------------
    
    % Update the total acquired indicator
    totalAcquired(count) = bigInd;
    
    % Register the time at which this loop finished
    tloop(count) = toc;
    
    count = count + 1;
    
end

stop(vid);


fclose(cmosFid);

set(vid,'TimerFcn',[]);
set(vid,'StopFcn',[]);
set(vid,'FramesAcquiredFcn',[]);

stats = stats(start_skip+1:totalAcquired(count-1),:);

fitData.cx = stats(:,3); fitData.cy = stats(:,4);
fitData.h = stats(:,2); fitData.sx = stats(:,5); fitData.sy = stats(:,6);
fitData.I = stats(:,2).*stats(:,5).*stats(:,6);
fitData.zNoCal = subPoly(-140*log(fitData.I),0);

results = batchPostProcessNoPSD(fitData,1/cmosFrameRate);
results.force = force;

cmosdT = 1/cmosFrameRate;
cmosTime = cmosdT:cmosdT:cmosdT*nCMOSFrames;

% Save relevant variables
save([dirname '\' basefilename '_info.mat'],'cmosStartTime','nCMOSFrames', ...
    'stackFactor','magX','magY','cmosFrameRate','numBigFrames','cmosFrameDims','cmosCropSize', ...
    'fitData','cmosTime','results');

plotResults(results);

fclose('all');
