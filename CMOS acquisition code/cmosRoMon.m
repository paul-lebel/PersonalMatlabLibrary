% Serves as a utility for previewing the angle, z, and power spectrum of a
% rotor bead.

% Author: Paul Lebel
% Date: June 2012
stop(vid); flushdata(vid);

% bigFrameSize = input('Big frame size?');
bigFrameSize = 100;
zDecay = 180;
fpt = get(vid,'FramesPerTrigger');
trep = get(vid,'TriggerRepeat');
set(vid,'FramesPerTrigger',inf);

bgFrame = takeBG(vid,100,'F:\',bigFrameSize,1);

frameRate = input('Frame rate?');
% frameRate=2000;
lagFactor = 2;
delay = 1;
magX = 93.33; % ROUGH! REDO MAG. CAL!!
magY = 93.33;
numBigFrames = round(delay*frameRate/bigFrameSize);
maxFrames = 1E6;
cropSize = [12 12];
croppedMovie = zeros(cropSize(1),cropSize(2),numBigFrames);
kappa = zeros(1000,1);
gamma = kappa; rBeadDrag = kappa;
nBasesTh = kappa;
tau = kappa;

scrsz = get(0,'ScreenSize');
prev = figure('Position',[50 600 400 380]);
set(gcf,'KeyPressFcn','keep=0');

prev2 = figure('Position',[500 600 900 380]);

set(gcf,'KeyPressFcn','keep=0');
colorbar; colormap gray;
set(0,'CurrentFigure',prev2);
ax1 = subplot(2,3,1);
ax2 = subplot(2,3,2);
ax3 = subplot(2,3,3);
ax4 = subplot(2,3,4); axis([0 1 0 1]);
ax5 = subplot(2,3,5);
ax6 = subplot(2,3,6);

bigFrameDims = vid.VideoResolution;
cmos_xsize = bigFrameDims(1);
cmos_ysize = bigFrameDims(2)/bigFrameSize;
smallFrameDims = [cmos_ysize cmos_xsize];
framePixels = cmos_xsize*cmos_ysize;

cropCoords = prevCrop(vid,smallFrameDims,1,cropSize,bigFrameSize);

% Data buffer for re-stacked data
squaredata = zeros(cmos_ysize,cmos_xsize,2*numBigFrames);
% Data buffer for direct from camera data
databuffer = zeros(cmos_ysize*bigFrameSize,cmos_xsize,1,2*numBigFrames);

tempframe = zeros(cmos_xsize,cmos_ysize);
stats = zeros(maxFrames,6);
cx = zeros(maxFrames,1); cy = cx; h = cx; I = cx; sx = cx; sy = cx; Offset = cx;

delay = 1;
keep = 1;
totalAcquired = zeros(maxFrames,1);

first = zeros(1e4,1); last = first; nFramesAcquired = 0; nTemp = 0;
nFrames = first; nPixels = first;
count = 1; % Loop index
tloop=0;
c2 = 1;
start(vid);
dt = 1/frameRate;

while((totalAcquired(count) < maxFrames) && (keep~=0) )
    
    pause(abs(delay-tloop));
    tic;
    
    framesAvailable = get(vid,'FramesAvailable');
    nFrames(count) = framesAvailable;
    
    if count ~=1
        totalAcquired(count) = totalAcquired(count-1) + nFrames(count);
    elseif count ==1
        totalAcquired(count) = nFrames(count);
    end
    
    
    disp(num2str(totalAcquired(count)));
    [databuffer, temptime] = getdata(vid,framesAvailable);
    squaredata = ReStackFrames(databuffer,[cmos_ysize cmos_xsize],bigFrameSize,framesAvailable);
    
    croppedMovie = squaredata(cropCoords(1,1):cropCoords(1,2)-1,cropCoords(1,3):cropCoords(1,4)-1,:);
    
    nPixels = prod(cropSize)*size(squaredata,3);
    
    tempframe = double(croppedMovie(:,:,end))-double(bgFrame(cropCoords(1):cropCoords(2)-1,cropCoords(3):cropCoords(4)-1));
    set(0,'CurrentFigure',prev);
    imagesc(tempframe); colormap(gray); text(0,0,num2str(max(tempframe(:)))); axis equal; drawnow;
    
    % Do 2D Gaussian fitting
    stats(bigFrameSize*(totalAcquired(count)-nFrames(count))+1:bigFrameSize*totalAcquired(count),:) = gsolve2d(double(croppedMovie(:)),[cropSize(2) cropSize(1)]);
        
   if mod(count,lagFactor)==0
        bigInd = totalAcquired(count)*bigFrameSize;
        time = dt:dt:dt*bigInd;
        cx = stats(1:bigInd,3)*magX;
        cy = stats(1:bigInd,4)*magY;
        [cx cy] = driftCorrect(cx,cy,1/2000);
        eStruct = fit_ellipse(cx,cy);
        [cx cy] = fixEllipticity(cx,cy,eStruct);
        angle = unwrap(atan2(cy,cx));
        set(0,'CurrentFigure',prev2);
        set(prev2,'CurrentAxes',ax2);
        plot(time,angle/(2*pi))
        set(prev2,'CurrentAxes',ax1);
        relateC(cx,cy,40); axis square;
        axis([-150 150 -150 150]);
        %         [psd f] = pwelch(subPoly(angle,0),[],[],[],2000);
        set(prev2,'CurrentAxes',ax3);
        cla;
        psdStats = psdAnalysis(angle, 1/frameRate,5); axis tight;
        set(prev2,'CurrentAxes',ax5); cla;
        zTemp = subPoly(-zDecay*log(stats(1:bigInd,2).*stats(1:bigInd,5).*stats(1:bigInd,6)),0);
        plot(time,zTemp,'b'); hold all;
        plot(time,zplp(zTemp,2000,50),'r');
        set(prev2,'CurrentAxes',ax4);
        cla;
        text(0.2,0.8,['\kappa = ' num2str((1E21)*psdStats.kappa,'%5.3f') ' pN nm/rad']);
        text(0.2,0.7,['\gamma = ' num2str((1E21)*psdStats.gamma,'%5.3f') ' pN nm s']);
        text(0.2,0.6,['\tau = ' num2str(psdStats.tau,'%5.3f') ' s']);
        text(0.2,0.5,['nBasesTh = ' num2str(psdStats.nBasesTh,'%5.3f') ' bp']);
        set(prev2,'CurrentAxes',ax6);
        [psdz fz] = pwelch(subPoly(zTemp,0),[],[],[],frameRate);
        loglog(fz,psdz); axis tight;
        drawnow;
        %         c2 = c2+1;
   end
    
    
    count = count+1;
    t = toc;
end

% if input('Process data? (1/0)')
    
    clear fitData;
    stats = stats(1:bigInd,:);
    fitData.cx = stats(:,3); fitData.cy = stats(:,4);
    fitData.h = stats(:,2); fitData.sx = stats(:,5); fitData.sy = stats(:,6);
    fitData.I = stats(:,2).*stats(:,5).*stats(:,6);
    fitData.zNoCal = subPoly(-zDecay*log(fitData.I),0);
    
    roMonResults = batchPostProcessNoPSD(fitData,1/frameRate);
    plotResults(roMonResults);
% end



stop(vid);
set(vid,'FramesPerTrigger',fpt);
set(vid,'TriggerRepeat',trep);
delete(prev);
delete(prev2);