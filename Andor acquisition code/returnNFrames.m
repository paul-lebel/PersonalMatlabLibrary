
% Function that will return N frames from the Andor under the current
% settings. 
% Modified to optionally control the shutter.
% LEF 2014 06 17
% function squaredata = returnNFrames(xsize,ysize,N,shutters)
% output squaredata is [xsize ysize frames]
function squaredata = returnNFrames(xsize,ysize,N,shutters)
last=0; first = 0;
[ret]=  SetAcquisitionMode(5);  
FreeInternalMemory();
nFrames = 0;
delay = .2;
totalAcquired = 0;
squaredata = zeros(xsize,ysize,N);
framesize = xsize*ysize;

if shutters
    [ret]=SetShutter(0, 1, 50, 50);                 %   Open the shutter
end


ret = StartAcquisition();

while (totalAcquired<N)
    pause(delay);
    
    [ret first last] = GetNumberNewImages();
    nFrames = last-first+1;
    nPixels = framesize*nFrames;
%     disp(num2str(totalAcquired));
    
    [grabret data(1:nPixels) validfirst validlast] = GetImages16(first,last,nPixels);
    squaredata(:,:,totalAcquired+1:totalAcquired+nFrames) = reshape(data(1:nPixels),[xsize,ysize,nFrames]);

    totalAcquired = totalAcquired + nFrames;
    
    imagesc(rot90(squaredata(:,:,totalAcquired),3)); axis image;
end


ret = AbortAcquisition();
if shutters
 [ret]=SetShutter(0, 2, 50, 50);                 %   Open the shutter
end
% [ret first last] = GetNumberNewImages();
% nFrames = last-first+1;
% [ret imagedata validfirst validlast] = GetImages16(first,last,xsize*ysize*nFrames);

% imagedata = reshape(double(imagedata),[xsize ysize nFrames]);
squaredata = squaredata(:,:,1:N);