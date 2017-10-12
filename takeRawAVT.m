% Take a raw video with the prosilica camera. Raw files require both byte
% swapping and Bayer conversion. This script does both and then saves the
% result to a .dat file. 

% To run this script you must have the camera initialized in RAW mode
% already

% Arguments: 
% vid = videoinput object
% numFrames = number of frames to acquire
% dirname = path to directory in which to save the raw rile
% filename = name of file to create. eg. 'mymovie.dat'
% rgb = vector of size [1 3] indicating which color channels to save. eg.
% if you want only red, use [1 0 0]. If you want all three, use [1 1 1].
% The channels will be saved in different 

function vidg = takeRawAVT(vid,numFrames,dirname,filename,rgb)
imaqmem(1E10);

bg = takeRawBG(vid,100,dirname);

set(vid,'framesperTrigger',numFrames);

% Get the movie's dimsensions and preallocate a buffer
temp = get(vid,'ROIposition');
dims(1) = temp(4); dims(2) = temp(3); clear temp;
dims(3) = 1;
dims(4) = numFrames;
movie = zeros(dims);
vidconv = zeros([dims(1) dims(2) 3 numFrames],'uint16');

start(vid);

while(isrunning(vid))
    pause(0.1);
end

[movie time] = getdata(vid,numFrames);
movie = squeeze(movie);
movie = swapbytes(movie);

% Convert raw 16 into something readable. This for loop is slow for large
% frame numbers
for i=1:numFrames
    vidconv(:,:,:,i) = demosaic(movie(:,:,i),'rggb');
end

% Taking one channel only, as specified by rgb
vidg = squeeze(double(mean(vidconv,3)));

clear vidconv movie;

% Subtract background from this movie
vidg = bsxfun(@minus,vidg,bg);

% Save the acquired movie to a raw data file
% fid = fopen([dirname '\' filename],'w');
% fwrite(fid,vidg,'double');
% fclose(fid);


