
% This script executes high-speed acquisition of rotor bead
% images. Once the image acquisition is started, frames are downloaded from
% the camera in batches. If desired (based on user input), images 
% are fit to a 2D Gaussian function, and proportional XY drift correction 
% feedback is applied to the stage to compensate for sample drift. Fitting 
% results and acquisition parameters are logged to a .mat file in the 
% same directory. 

% Initialize.m should be run before this script.

% Hardware requirements:

% An Andor Ixon+ EMCCD camera is controlled by using the manufacturer's 
% provided Matlab adaptor functions. 

% A Mad City Labs PDQ nanopositioning stage connected to a Nanodrive
% controller is sent commands by calling dll library functions provided by
% the manufacturer. This script assumes that the stage has been
% initialized and moved away from the boundaries of its motion range. 


% Author: Paul Lebel
% (some commands based on examples provided by Andor and Mad City Labs)


%-----------Parameters to be set manually----------------------------------
% Set the quasi-realtime period (seconds)
loopDelay = 1;

% Set the number of movies
nMovies = 3;

% Enter the size of the isolated crop region
cropsize = [10 10];

% Setpoints for x-y feedback stabilization 
xSet = 4.5;
ySet = 4.5;

% Camera exposure time (s)
exposureSet = 0.0005;
%--------------------------------------------------------------------------

% Read the current piezo positions
xnow = calllib('Madlib','MCL_SingleReadN',1,mcl_handle);
ynow = calllib('Madlib','MCL_SingleReadN',2,mcl_handle);

% Retrieve inputs from the user
dirname = uigetdir('Select directory to save');
basefilename = input('Base file name? ','s');
fitFlag = input('Do (quasi) realtime gaussian fitting?','s');
totalFrames = input('Number of frames per movie? ');

% Create filenames for movies
clear filename
for k=1:nMovies
    filename{k} = [basefilename '_' num2str(k)];
end

% Configure the Andor camera
SetFanMode(2)                                                         %   Turn fan off
SetShutter(0, 2, 50, 50);                                             %   Close shutter
SetTriggerMode(0);                                                    %   Set trigger mode; 0 for Internal, 6 external start, 10 software
SetNumberAccumulations(1);                                            %   One image per frame
SetReadMode(4);                                                       %   Set read mode; 4 for Image
SetAcquisitionMode(5);                                                %   Set acquisition mode; 1 for Single Scan, 3 for kinetic, 5 for run till abort
SetFrameTransferMode(1);                                              %   Use frame transfer mode
SetVSSpeed(1);                                                        %   Sets VS speed to 0.5us
SetVSAmplitude(1);                                                    %   Extra voltage helps when fast shift speeds are used
SetIsolatedCropMode(1,cropsize(1),cropsize(2),1,1);                   %   Set isolated crop mode and define crop region
SetHSSpeed(0,0);                                                      %   Set horizontal shift speed
SetExposureTime(exposureSet);                                         %   Set the exposure (approximate - actual exposure will be queried from the camera)
SetEMCCDGain(10);                                                     %   In practice, gain should be tuned prior to an acquisition to achieve appropriate signal levels

% Get camera parameters
[~, EMgain] = GetEMCCDGain();
[~,xsize, ysize]=GetDetector;                                         %   Get the image size
framesize = xsize*ysize;                                              %   Number of pixels in a frame
[~,Exposure, Accumulate, Kinetic] = GetAcquisitionTimings;            %   Get actual timing values
frameRate = 1/Kinetic;                                                %   Kinetic cycle time is the total time to acquire and shift a frame

% Display the framerate, and the total duration of the acquisition
disp(frameRate);
acqTime = totalFrames/framerate;
disp(acqTime);

% Pre-allocate a temporary data buffer for images. One linear vector and
% one 3D stack
data = int16(zeros(loopDelay*round(framerate)*framesize*2,1)); 
squaredata = zeros(xsize,ysize,totalFrames);

% Memory used to display a preview
tempframe = zeros(xsize,ysize);

% fitFlag toggles whether image fitting (and xy drift feedback) will be
% performed. If so, allocate memory for the fit parameters.
if fitFlag=='y'
    stats = zeros(totalFrames,6,nMovies);
end

% Check status of the camera
[ret,gstatus]=AndorGetStatus;
while(gstatus ~= 20073)%DRV_IDLE
    pause(1.0);
    disp('Not ready');
    [ret,gstatus]=AndorGetStatus;
end

%   Open shutter 
SetShutter(0, 1, 50, 50);

% Loop to acquire multiple movies
for k = 1:nMovies
    
    % Allows user to change experimental parameters between movies. Hit
    % 'enter' to continue
    temp = input('Pause to set desired parameters');
    clear temp;
    
    % Create and open a binary data file for the movie
    fidmovie(k) = fopen([dirname '\' filename{k} '_movie.dat'],'w');
    
    % Reset the movie data to zeros
    squaredata = zeros(xsize,ysize,totalFrames);
    
    % Prepare the Andor for acquisition
    FreeInternalMemory();
    PrepareAcquisition();
    
    % Initialize the camera status flags
    gstatus = 20072;
    grabret = 20002;
    
    % Reset the running total of frames acquired
    totalAcquired = 0;
    
    % Initialize indices for frames acquired during the loop
    first = zeros(1e4,1); last = first; nFramesAcquired = 0; nTemp = 0;
    nFrames = first; nPixels = first;
    count = 2; % Loop index
    tloop= zeros(1E4,1);
    
    % Starts the Andor's acquisition
    StartAcquisition;
    
    % Start timer
    tic;
    
    % Acquisition loop runs until all the frames are acquired or until an
    % error is detected
    while((totalAcquired < totalFrames) && (gstatus == 20072) && (grabret == 20002))
        
        
        % Pause to allow sufficient frames to accumulate before grabbing
        % from the camera
        pause(max( (loopDelay-(tloop(count)-tloop(count-1))),.001) );
       
        % Query the camera to ask how many new frames have arrived
        [ret, first(count), last(count)] = GetNumberNewImages();
        nFrames(count) = last(count)-first(count)+1;
        nPixels(count) = framesize*nFrames(count);
        totalAcquired = totalAcquired + nFrames(count);
        
        % Display the number of frames acquired 
        disp([num2str(totalAcquired) ' frames acquired']);
              
        % Grab images; they come as a linear vector. 
        % Preview the most recent frame after reshaping
        [grabret, data(1:nPixels(count)), validfirst, validlast] = GetImages16(first(count),last(count),nPixels(count));
        tempframe = reshape(data((nPixels(count)-framesize+1):nPixels(count)),[xsize ysize]);
        imagesc(rot90(tempframe,3)); colormap(gray); 
        
        % Display the maximum pixel value of this frame as text. This is
        % used to monitor signal level
        text(0,0,num2str(max(tempframe(:))));       
        
        % Write the current chunk of movie to disk
        fwrite(fidmovie(k),data(1:nPixels(count)),'uint16');        
        
        % Do 2D Gaussian fitting with the stack-optimized C function
        % gsolve2d
        if fitFlag=='y'
            stats((totalAcquired-nFrames(count)+1):totalAcquired,:,k) = gsolve2d(double(data(1:nPixels(count))),[xsize ysize]);
        end
        
        % Do xy drift correction by fitting a circle to the tracking data.
        % Gains of less than unity are used to ensure stability
        if (mod(count,2) ==0 && fitFlag =='y' && count > 4)
            
            % Fit a circle to the x-y positions to determine the center
            [ydrift xdrift r] = circleFit(stats((totalAcquired-nFrames(count-1)+1):totalAcquired,3,k),stats((totalAcquired-nFrames(count-1)+1):totalAcquired,4,k));           
            
            % Compute new x-y positions using proportional gain less than
            % unity for stability
            xnow = xnow + .5*(xdrift-xSet)*.105;
            ynow = ynow + .5*(ydrift-ySet)*.105;
            
            % Write the positions to the stage
            temp = calllib('Madlib','MCL_SingleWriteN',xnow,1,mcl_handle);
            temp = calllib('Madlib','MCL_SingleWriteN',ynow,2,mcl_handle);
        end
               
        % Check camera status
        [ret,gstatus]=AndorGetStatus;       
        
        % Increment the loop count
        count = count+1;
    end
    
    % Stop the Andor's acquisition
    AbortAcquisition();
    
    % Close the binary file
    fclose(fidmovie(k));
    
    % Limit the number of frames to the desired total
    if fitFlag=='y'
        stats = stats(1:totalFrames,:,:); 
    end
    
    % Verify if any frames were dropped
    dropCheck = first(2:count-1)-last(1:count-2);
    if ( sum(dropCheck ~= 1) > 0 )
        disp('Warning! Dropped frames');
    else
        disp('No frames dropped');
    end
    
end

%   Close the shutter
ret=SetShutter(0, 2, 50, 50);

% Save the fit parameters and other relevant information to a .mat file
if fitFlag =='y'
    save([dirname '\info.mat'],'stats','xsize','ysize','totalAcquired','first','last','Kinetic','EMgain','k');  
else
    save([dirname '\info.mat'],'xsize','ysize','totalAcquired','first','last','Kinetic','EMgain','k');
end



