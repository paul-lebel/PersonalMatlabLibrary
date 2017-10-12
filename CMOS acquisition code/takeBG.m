% Capture a background frame by taking a movie, averaging
% frames, then save the frame as a .mat file in the specified directory

% Author: Paul Lebel
% Date: Sept. 8th, 2011

% Input arguments:
%  vidobj: video input object for the image acquisition toolbox
%  numFrames: number of frames to average when taking background image
%  

function bg = takeBG(vidobj,numFrames,dirname,bigFrameSize,isStack)

% Record original settings of the vid object, in order to restore them
% afterwards
fptOrig = get(vidobj,'FramesPerTrigger');
trigRepOrig = get(vidobj,'TriggerRepeat');
temp = get(vidobj,'VideoResolution');
smallFdims(2) = temp(1);
smallFdims(1) = temp(2); clear temp;

% Accomodate for the possibility of stacked frames
if isStack
    numFrames = floor(numFrames/bigFrameSize);
    smallFdims(1) = smallFdims(1)/bigFrameSize;
end

% Configure the vid object
set(vidobj,'FramesPerTrigger',numFrames);
set(vidobj,'TriggerRepeat',0);

% Allow user to turn off light sources (for the automatically functioning
% version of this function, see 'takeBGAuto'
answer = input('Turn off all light sources the hit enter','s');

start(vidobj);

while(isrunning(vidobj))
    pause(.01);
end

% Download data from the framegrabber
bg = getdata(vidobj,numFrames);
if isStack
    bg = ReStackFrames(bg,smallFdims,bigFrameSize,numFrames);
end

% Average the frames; save the bgFrame
bg = squeeze(bg);
bg = mean(bg,3);
save([dirname '\bg.mat'], 'bg')
    
% Restore previous settings
set(vidobj,'FramesPerTrigger',fptOrig);
set(vidobj,'TriggerRepeat',trigRepOrig);

% answer = input('Turning IR back on','s');



    