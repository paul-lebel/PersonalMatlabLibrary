% Set up the Andor camera for highspeed data acquisition
% Author: Paul Lebel
% Date: June 2012
clear filename

% force = [0.25 0.5 1 5];
% force = 1.2;
% magPos = Ftoh_halfI

loopDelay = 1;

xSet = 4.3;
ySet = 4.3;
xnow = readX(1); % Current piezo position x
ynow = readY(1); % Current piezo position y


start_path = 'F:\Paul_Data\2014\April';
dirname = uigetdir(start_path,'Select directory to save');
basefilename = input('Base file name? ','s');
% fitFlag = input('Do (quasi) realtime gaussian fitting?','s');
totalFrames = input('Number of frames per movie? ');
spinflag = input('Spin the magnets? ','s');
nMovies = numel(magPos);


for k=1:numel(magPos)
    filename{k} = [basefilename '_' num2str(k) '_' num2str(magPos(k)) 'mm'];
end

[ret] = SetFanMode(2)                           %   Turn fan off
[ret]=SetShutter(0, 2, 50, 50);                 %   Close shutter
% [ret]=CoolerON;                                 %   Turn on temperature cooler
% [ret] = SetTemperature(-40);                     %   Set temperature
[ret]=SetTriggerMode(0);                        %   Set trigger mode; 0 for Internal, 6 external start, 10 software
[ret] = SetNumberAccumulations(1);              %   One image per frame
[ret]=SetReadMode(4);                           %   Set read mode; 4 for Image
[ret]=SetAcquisitionMode(5);                    %   Set acquisition mode; 1 for Single Scan, 3 for kinetic, 5 for run till abort
[ret] = SetFrameTransferMode(1);                %   Use frame transfer mode
[ret] = SetVSSpeed(1);                          %   Sets to 0.5us
[ret] = SetVSAmplitude(1);                      %   Helps for fast shift speeds
[ret] = SetIsolatedCropMode(1,cropsize(1),cropsize(2),1,1);       %   Isolated crop to go as fast as possible :)
[ret,nospeeds]=GetNumberHSSpeeds(0,0);
[ret] = SetHSSpeed(0,0);
% [ret]=SetPreAmpGain(1);                          %   0: 1; 1: 2.3; 2: 4.9
% [ret]=SetEMGainMode(3);
[ret EMgain]=GetEMCCDGain()
% 
% [ret]=SetExposureTime(0.000001);                %   Exposure will be determined by framerate
[ret,xsize, ysize]=GetDetector;             %   Get the image size
framesize = xsize*ysize;

[ret,Exposure, Accumulate, Kinetic]=GetAcquisitionTimings;    %   Get acquisition setting
frameRate = 1/Kinetic
[ret circBufsize] = GetSizeOfCircularBuffer();

framerate = 1/Kinetic; disp(framerate);
acqTime = totalFrames/framerate; disp(acqTime);
data = zeros(loopDelay*round(framerate)*framesize*2,1);                 %   Allocate temp storage for images
squaredata = zeros(xsize,ysize,totalFrames);

tempframe = zeros(xsize,ysize);

if fitFlag=='y'
    stats = zeros(totalFrames,6);
    cx = zeros(totalFrames,nMovies); cy = cx; h = cx; I = cx; sx = cx; sy = cx; Offset = cx;
end

[ret,gstatus]=AndorGetStatus;
while(gstatus ~= 20073)%DRV_IDLE
    pause(1.0);
    disp('Not ready');
    [ret,gstatus]=AndorGetStatus;
end

if spinflag == 'y'
    temppos = magnetAngle_obj.qPOS('1');
    magnetAngle_obj.MOV('1',temppos + 1E5);
end
%   Open shutter and wait a bit. Closed: (0,2,50,50)
[ret]=SetShutter(0, 1, 50, 50);


% Loop to acquire multiple movies
for k = 1:nMovies
    
%     setForce(magnetHeight_obj,force(k)); 
%     pause(5);
    
    fidmovie(k) = fopen([dirname '\' filename{k} '_movie.dat'],'w');
    
    squaredata = zeros(xsize,ysize,totalFrames);
    
    %Set magnet position 
    if (magPos(k) <= 24.5) && (magPos(k) >= 0);
        magnetHeight_obj.MOV('1',magPos(k));
        while ~magnetHeight_obj.qONT('1')
            pause(0.1)
        end
    else
        disp('Magnet position value must be within [0 24.5]')
    end    
    disp(['Magnet position set to ' num2str(magPos(k)) 'mm'])
    pause(5)
    
    % Start the acquisition
    ret = FreeInternalMemory();
    [ret] = PrepareAcquisition();
    pause(.5);
    
    gstatus = 20072;
    grabret = 20002;
    
 
    totalAcquired = 0;
    
    first = zeros(1e4,1); last = first; nFramesAcquired = 0; nTemp = 0;
    nFrames = first; nPixels = first;
    grabret = 20002;
    count = 2; % Loop index
    tloop= zeros(1E4,1);
    
    StartAcquisition;
    
%     t1 = zeros(1E4,1); t2 = t1; t3 = t1; t4 = t1; t5 = t1; t6 = t1;
    
    tic;
  
    while((totalAcquired < totalFrames) && (gstatus == 20072) && (grabret == 20002))
        
%         t6(count) = toc;
%         tic;
        
        pause(max( (loopDelay-(tloop(count)-tloop(count-1))),.001) );
        
           
%         pause(.02);

        tpause(1) = cputime; tpause(2) = cputime;
        while( (tpause(2)-tpause(1)) < loopDelay)
            tpause(2) = cputime;
        end
        
        
%         t1(count) = toc;

        [ret first(count) last(count)] = GetNumberNewImages();
        nFrames(count) = last(count)-first(count)+1;
        nPixels(count) = framesize*nFrames(count);
        totalAcquired = totalAcquired + nFrames(count);
        
%         t2(count) = toc;
        
        disp(num2str(totalAcquired));
        
        [grabret data(1:nPixels(count)) validfirst validlast] = GetImages16(first(count),last(count),nPixels(count));
        tempframe = reshape(data((nPixels(count)-framesize+1):nPixels(count)),[xsize ysize]);
        imagesc(rot90(tempframe,3)); colormap(gray); text(0,0,num2str(max(tempframe(:)))); axis image;

%         t3(count) = toc;
        
        % Write the chunk of movie to disk        
        fwrite(fidmovie(k),data(1:nPixels(count)),'uint16');
        
%         t4(count) = toc;
        
        % Do 2D Gaussian fitting
        if fitFlag=='y'
%             squaredata(:,:,(totalAcquired-nFrames(count)+1):totalAcquired) = reshape(data(1:nPixels(count)),[xsize ysize nFrames(count)]);
            stats((totalAcquired-nFrames(count)+1):totalAcquired,:) = gsolve2d(double(data(1:nPixels(count))),[xsize ysize]);
        end
        
%         
        if (mod(count,2) ==0 & fitFlag =='y' & count > 4)
        [ydrift xdrift r] = circleFit(stats((totalAcquired-nFrames(count-1)+1):totalAcquired,3),stats((totalAcquired-nFrames(count-1)+1):totalAcquired,4));
        
        xnow = xnow + .5*(xdrift-xSet)*.105;
        ynow = ynow + .5*(ydrift-ySet)*.105;
        piezoX(mcl_handle,xnow);
        piezoY(mcl_handle,ynow);
        
        end
        
        
        % Check camera status
        [ret,gstatus]=AndorGetStatus;
        
        
%         tloop(count) = toc;
%     t5(count) = toc;
    
    count = count+1;
    end
    
    [ret] = AbortAcquisition();
    fclose(fidmovie(k));

        
    if fitFlag=='y'
%         squaredata = squaredata(:,:,1:totalFrames);
        
        stats = stats(1:totalFrames,:);
        [ydrift xdrift ro] = circleFit(stats((totalFrames-50000+1):totalFrames,3),stats((totalFrames-50000+1):totalFrames,4));
        xnow = xnow + .5*(xdrift-xSet)*.105;
        ynow = ynow + .5*(ydrift-ySet)*.105;
        piezoX(mcl_handle,xnow);
        piezoY(mcl_handle,ynow);
    end
    
    % save([dirname '\' filename{k} '_movie.mat'],'squaredata');
    
    if fitFlag=='y'
        Offset(:,k) = stats(:,1);
        h(:,k) = stats(:,2);
        cx(:,k) = stats(:,3);
        cy(:,k) = stats(:,4);
        sx(:,k) = stats(:,5);
        sy(:,k) = stats(:,6);
        I(:,k) = sx(:,k).*sy(:,k).*h(:,k);
        stats = zeros(totalFrames,6);
    end
    
    
    dropCheck = first(2:count-1)-last(1:count-2);
    if ( sum(dropCheck ~= 1) > 0 )
        disp('Warning! Dropped frames');
    else
        disp('No frames dropped');
    end
    
end


% s_lock.stop;
%     setForce(magnetHeight_obj,0.5)


%   Close the shutter
[ret]=SetShutter(0, 2, 50, 50);
disp('Status at end:')
[ret,gstatus]=AndorGetStatus
% s.stop

magnetHeight_obj.MOV('1',17)
if spinflag == 'y'
    temppos = magnetAngle_obj.qPOS('1');
    magnetAngle_obj.MOV('1',temppos - mod(temppos,180)); pause(1);
    magnetAngle_obj.POS('1',0);
end

if fitFlag =='y'
    save([dirname '\analysis.mat'],'xsize','ysize','totalAcquired','first','last','Kinetic','EMgain','magPos','k');
    stats.cx = cx;
    stats.cy = cy;
    stats.I = I;
    stats.Offset = Offset;
    stats.sx = sx;
    stats.sy = sy;
    stats.h = h;
    
    clear cx cy I Offset sx sy h;
    
    results = batchPostProcessNoPSD(stats,Kinetic);
    save([dirname '\resultspp.mat'],'results');
    
else
    save([dirname '\' filename{k} 'info.mat'],'xsize','ysize','totalAcquired','first','last','Kinetic','EMgain','magPos','k');
end

clear data;
% clear stats;
% clear squaredata;


