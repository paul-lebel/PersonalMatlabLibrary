
% Realtime acquisition loop interfacing with the Mikrotron camera at high
% frame rates. This script acquires data from the Bitflow framegrabber
% using stacked frames (100 frames per DMA)

% This code sets the grabbers's frames per trigger value to infinity, so the
% camera simply streams a flow of data to its indefinitely and we grab it as needed. The
% timed loop ensures no data is missed

% This is a barebones acquisition function: no background subtracking, no
% realtime tracking, no feedback, etc.


% Author: Paul Lebel
% Feb. 2013, modified from Paul Lebel April 2011


function [time, smallFbuff] = spoolCMOS_stack_barebones_10bit(vid,numFrames,pathname,filename,bigFrameSize)

bigFperLoop = 10;
numclass = 'uint16';

%-------Script parameters - should not change on a daily basis-------------
% Set some bitflow parameters
imaqmem('FrameMemoryLimit');
set(vid,'FramesPerTrigger',inf);
set(vid,'TriggerRepeat',0);
set(getselectedsource(vid),'BuffersToUse',100);

count = 1; fA = 0;
maxcount = 1+floor(numFrames/(bigFrameSize*bigFperLoop));

% Get small frame dimensions
vidRes = get(vid,'VideoResolution');
Framesize(1) = floor(vidRes(2)/bigFrameSize);
Framesize(2) = vidRes(1); clear temp;

% Memory devoted to image acquisition toolbox. 8 bytes/pixel. 4 is an
% arbitrary safety factor
% imaqmem(4*prod(Framesize)*8*bigFperLoop*bigFrameSize);
imaqmem(12E9);
%--------------------------------------------------------------------------


% Pre-allocate data buffers
smallFbuff = zeros(Framesize(1),Framesize(2),bigFperLoop*bigFrameSize);
frametimes = cell(maxcount,1);
t1 = zeros(maxcount,1); t3 = t1; tL = t1;

% Create directory for this movie
fid1 = fopen([pathname filename],'w');

stop(vid);
flushdata(vid);

% Capture a background frame and save it to disk for subtracting later
bgFrame = int16(takeBG(vid,100,pathname,bigFrameSize,1));
save([pathname [filename '_bg.mat']],'bgFrame');

% Lights, camera, action!
start(vid);

%--------------------------------------------------------------------------
% Realtime acquisition loop.
%--------------------------------------------------------------------------
while(count<maxcount)
    % Start timer
    tic;
    
    % Compute the actual frame indices for this loop (litInd = start,
    % bigInd  = end)
    litInd = 1+(count-1)*bigFrameSize*bigFperLoop;
    bigInd = count*bigFrameSize*bigFperLoop;
    
    % Wait for requested number of frames, then immediately grab them
    while(get(vid,'FramesAvailable') < bigFperLoop)
        pause(.0005);
    end
    
    % Grab big frames
    [databuffer, frametimes{count}] = getdata(vid,bigFperLoop);
    t1(count) = toc; 
    disp([num2str(t1(count)) ' s to grab data']);
    fwrite(fid1,databuffer,numclass);
    t3(count) = toc; 
    disp([num2str(t3(count)-t3(count)) ' s to write to disk']);
    
    % Update preview display
    imagesc(squeeze(databuffer((vidRes(2)-Framesize(1)+1):vidRes(2),:,1,end))); axis equal; pause(.001);
   
%     Display acquisition info
    fprintf('Wrote frames %i to %i \n',litInd,bigInd);    
    
    % Record the total loop time and display it
    tL(count) = toc;
    disp([num2str(tL(count)-t3(count)) ' s to display preview']); disp(' '); 
    
    % Increment the loop counter
    count = count+1;
end

% Tidy things up: stop acquisition, close data files, clear temporary
% buffers
stop(vid)
flushdata(vid)
fclose(fid1);
    
% Convert the cell array of frame times into a vector
temp = [frametimes{:};];
time = temp(:); clear temp frametimes;
time = time-time(1);

% Plot the timing variables
figure; subplot(2,1,1);
plot(t1); hold all;  plot(t3); plot(tL)
subplot(2,1,2);
plot(diff(time));

% Save all the meta data
save([pathname filename '_info.mat'],'time','numFrames','numclass');



