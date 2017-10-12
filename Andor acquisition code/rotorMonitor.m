% Set up the Andor camera for highspeed data acquisition
% Author: Paul Lebel
% Date: June 2012

delay = .5;
lagFactor = 5;
magX = 106.5;
magY = 103.13;

totalFrames = 1E6;
[ret]=SetAcquisitionMode(5);                    %   Set acquisition mode; 1 for Single Scan, 3 for kinetic, 5 for run till abort
[ret] = SetFrameTransferMode(1);                %   Use frame transfer mode
[ret] = SetVSSpeed(1);                          %   Sets to 0.5us
[ret] = SetVSAmplitude(1);                      %   Helps for fast shift speeds
[ret] = SetIsolatedCropMode(1,cropsize(1),cropsize(2),1,1);       %   Isolated crop to go as fast as possible :)
[ret,nospeeds]=GetNumberHSSpeeds(0,0);
[ret] = SetHSSpeed(0,0);
% [ret]=SetPreAmpGain(0);                          %   0: 1; 1: 2.3; 2: 4.9
% [ret]=SetEMGainMode(3);
[ret EMgain]=GetEMCCDGain();

scrsz = get(0,'ScreenSize');
prev = figure('Position',[50 600 400 350])
set(gcf,'KeyPressFcn','keep=0');
colorbar; colormap gray; 
datafig = figure('Position',[500 600 400 350]);
set(gcf,'KeyPressFcn','keep=0');
histfig = figure('Position',[950 600 400 350]);


% [ret]=SetExposureTime(0.000001);                %   Exposure will be determined by framerate
[ret,xsize, ysize]=GetDetector;             %   Get the image size
framesize = xsize*ysize;

[ret,Exposure, Accumulate, Kinetic]=GetAcquisitionTimings;    %   Get acquisition setting
frameRate = 1/Kinetic
[ret circBufsize] = GetSizeOfCircularBuffer();

framerate = 1/Kinetic; disp(framerate); 
acqTime = totalFrames/framerate; disp(acqTime);
data = zeros(delay*round(framerate)*framesize*2,1);                 %   Allocate temp storage for images
squaredata = zeros(xsize,ysize,totalFrames);

tempframe = zeros(xsize,ysize);

stats = zeros(totalFrames,6);
cx = zeros(totalFrames,1); cy = cx; h = cx; I = cx; sx = cx; sy = cx; Offset = cx;


[ret,gstatus]=AndorGetStatus;
while(gstatus ~= 20073)%DRV_IDLE
  pause(1.0);
  disp('Not ready');
  [ret,gstatus]=AndorGetStatus;
end

%   Open shutter and wait a bit. Closed: (0,2,50,50)
[ret]=SetShutter(0, 1, 50, 50);


% Loop to acquire multiple movies
    squaredata = zeros(xsize,ysize,totalFrames);
    
% Start the acquisition
ret = FreeInternalMemory();
[ret] = PrepareAcquisition();
pause(.5);                             

gstatus = 20072;
grabret = 20002;

delay = 1;
nPixels = 0;
keep = 1;
% totalFrames = 2e5;
totalAcquired = 0;

first = zeros(1e4,1); last = first; nFramesAcquired = 0; nTemp = 0; 
nFrames = first; nPixels = first;
grabret = 20002;
count = 1; % Loop index
tloop=0;

StartAcquisition; 

while((totalAcquired < totalFrames) && (gstatus == 20072) && (grabret == 20002) && (keep~=0) )
    pause(abs(delay-tloop));
    tic;
    [ret first(count) last(count)] = GetNumberNewImages();
    nFrames(count) = last(count)-first(count)+1;
    nPixels(count) = framesize*nFrames(count);
    totalAcquired = totalAcquired + nFrames(count);
    disp(num2str(totalAcquired));
    
    [grabret data(1:nPixels(count)) validfirst validlast] = GetImages16(first(count),last(count),nPixels(count));
    tempframe = reshape(data((nPixels(count)-framesize+1):nPixels(count)),[xsize ysize]);
    set(0,'CurrentFigure',prev);
    imagesc(tempframe); colormap(gray); text(0,0,num2str(max(tempframe(:)))); axis equal;
    squaredata(:,:,(totalAcquired-nFrames(count)+1):totalAcquired) = reshape(data(1:nPixels(count)),[xsize ysize nFrames(count)]);
    
%     fwrite(fid1,data(1:nPixels(count)),'uint16');
    
    
    % Do 2D Gaussian fitting 
    stats((totalAcquired-nFrames(count)+1):totalAcquired,:) = gsolve2d(double(data(1:nPixels(count))),[xsize ysize]);
  
     % Check camera status
    [ret,gstatus]=AndorGetStatus;
    
    if mod(count,lagFactor)==0
        cx = stats(1:totalAcquired,3)*magX;
        cy = stats(1:totalAcquired,4)*magY;        
        [cx cy] = driftCorrect(cx,cy,Kinetic);
        eStruct = fit_ellipse(cx,cy);
        [cx cy] = fixEllipticity(cx,cy,eStruct);
%         cx = cx-eStruct.X0_in;
%         cy = cy-eStruct.Y0_in;
        angle = unwrap(atan2(cy,cx));
        set(0,'CurrentFigure',datafig);
        plot(angle)
        set(0,'CurrentFigure',histfig);
        relateC(cx,cy,40); axis square; 
        axis([-150 150 -150 150]);
    end    

    
    count = count+1;
    t = toc
end

[ret] = AbortAcquisition();
%   Close the shutter
[ret]=SetShutter(0, 2, 50, 50);  
disp('Status at end:')
[ret,gstatus]=AndorGetStatus

% 
% tempresults = batchPostProcessNoPSD(stats,Exposure);
% 
% relateC(tempresults.cx_dc,tempresults.cy_dc,100);
% figure;
% plot(tempresults.time,tempresults.angle);