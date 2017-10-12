
% Interactive function to read in a large raw movie file, crop it, and save the cropped
% region as a separate file. 

% dims: a 3-element vector (or 2 if it's only 1 frame) containing the
% size of the movie: [height width numFrames]

% type: string with the datatype of the raw file (eg.
% 'double','uint16',...)

function cropRawMovie(dims,type);

numPreFrames = min(dims(3),100);

preVid = zeros(dims(1),dims(2),numPreFrames);

[filename pathname] = uigetfile('*.dat');

fid = fopen([pathname filename],'r');

% Number of frames to read at once. Should work on most computers; increase
% this value for long movies if you have enough memory.
chunksize = 100;
numChunks = floor(dims(3)/chunksize);
nRemaining = rem(dims(3),chunksize);
frameSize = prod(dims(1:2));
chunkpixels = frameSize*chunksize;


% Show a brief preview and allow the user to select a crop region
preVid = fread(fid,frameSize*numPreFrames,type); frewind(fid);
disp('Displaying brief preview...'); disp('');
preVid = reshape(preVid,[dims(1) dims(2) numPreFrames]);
playvid(preVid,1:numPreFrames,50);
% figh = imagesc(preVid(:,:,numPreFrames));

disp('Drag a box and position it over the desired crop region'); 
disp('Double-click on the box to set region'); disp('');

h = imrect();
cropcoords = wait(h);
cropcoords = round(cropcoords);
% delete(figh);

newFileName =input('Please type the filename for the cropped region \n','s');

% Create a new file for writing the cropped movie
fidnew = fopen([pathname newFileName],'w');

% Cycle through and crop the video, saving the cropped region to a new file
for i=1:numChunks
    ind1 = 1+(i-1)*chunksize;
    ind2 = i*chunksize;
    chunk = fread(fid,chunkpixels,type);
    chunk = reshape(chunk,[dims(1) dims(2) chunksize]);
    fwrite(fidnew,chunk(cropcoords(2):cropcoords(2)+cropcoords(4), ...
        cropcoords(1):cropcoords(1)+cropcoords(3),:),type);
    
end

if nRemaining > 0
    chunk = fread(fid,nRemaining*frameSize,type);
    chunk = reshape(chunk,[dims(1) dims(2) nRemaining]);
    
    fwrite(fidnew,chunk(cropcoords(2):cropcoords(2)+cropcoords(4), ...
        cropcoords(1):cropcoords(1)+cropcoords(3),:),type);
end

xOffset = cropcoords(1);
yOffset = cropcoords(2);

newdims = round([cropcoords(4)+1,cropcoords(3)+1,dims(3)]);

% Save the info structure associated with this movie
save([pathname newFileName '_info.mat'],'newdims','xOffset','yOffset');

fclose(fid); fclose(fidnew);

clear chunk
    
    