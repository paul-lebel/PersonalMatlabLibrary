
% Basic movie acquisition with the CMOS, including background subtraction. 


function bg = takeCMOSvid(vid,numFrames,dirname,filename)

% Set memory limit for image acquisition
imaqmem(1E12);

% Get the image size. Warning: with the CMOS, never set the ROI position
% through Matlab. This does not tell the camera itself to change ROI size;
% only the framegrabber.

temp = get(vid,'VideoResolution');
Framesize(1) = temp(2); Framesize(2) = temp(1); clear temp;

% Grab a background frame to subtract
bg = int16(takeBG(vid,10,dirname,20,0));

% Set the number of frames to grab
set(vid,'FramesperTrigger',numFrames);

% Begin acquiring
start(vid);
pause(.1);

% Wait for acquisition and display preview
while(isrunning(vid))
    temp = int16(peekdata(vid,1));
    imagesc(squeeze(temp-bg)); axis image;
    pause(.1);
end

% Get the data
[movie, time] = getdata(vid,numFrames);
time = time - time(1);

disp('Done acquiring movie');


% Remove the extra dimension in the variable
movie = int16(squeeze(movie));

% Subtract background using fast, binary math
movie = bsxfun(@minus,movie,bg);

% Create a file to save the movie in, and write to disk
fid = fopen([dirname '\' filename],'w');
fwrite(fid,movie,'int16');
fclose(fid);

disp('saving data now');

% Save the info structure associated with this movie
save([dirname '\' filename '_info.mat'],'time','Framesize','numFrames');
