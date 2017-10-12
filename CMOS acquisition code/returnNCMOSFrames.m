
% Function that will return a number of frames from the CMOS under the current
% settings.

function imagedata = returnNCMOSFrames(vid,N,stack,bigFrameSize)

set(vid,'TriggerRepeat',0);
temp = get(vid,'VideoResolution');
xsize = temp(1); ysize = temp(2);

if stack
    numBigFrames = max(1,floor(N/bigFrameSize));
    set(vid,'FramesPerTrigger',numBigFrames);
    start(vid);
    while(isrunning(vid))
        pause(.01);
    end
    
    imagedata = getdata(vid);
    imagedata = reshape(double(imagedata),[ysize xsize numBigFrames]);
    imagedata = ReStackFrames(imagedata,[floor(ysize/bigFrameSize) xsize],bigFrameSize,numBigFrames);
else
    
set(vid,'FramesPerTrigger',N);
start(vid);
% Wait for the acquisition to finish
while(isrunning(vid))
    pause(.01);
end

imagedata = getdata(vid);
imagedata = reshape(double(imagedata),[ysize xsize N]);

end
imagedata = imagedata(:,:,1:N);


