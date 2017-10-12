% Capture a background frame by taking a movie, averaging
% frames, then save the frame as a .mat file in the specified directory.
% This version of the function automatically turns off the excitation
% sources by controlling them through the daq ('sdaq2')

% Author: Paul Lebel
% Date: Sept. 8th, 2011

% Input arguments:
%  vidobj: video input object for the image acquisition toolbox
%  numFrames: number of frames to average when taking background image
%  

function bg = takeBGAuto(vidobj,numFrames,dirname,bigFrameSize,isStack)

% Global variables used to control the daq. 'present_daq2Vals' is a global
% variable that keeps track of the output status of the daq channels
% controlled by sdaq2 (see globalControls.m)
global sdaq1 sdaq2 present_daq2Vals digiStates

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

% Shutting off light sources for bg frame collection
disp('Turning off IR');
sdaq2.outputSingleScan([-.1 -.1]);
sdaq1.outputSingleScan(zeros(size(digiStates)));
pause(0.2);

% Start the vid and wait for it to complete
start(vidobj);
while(isrunning(vidobj))
    pause(.01);
end

% Get the data from the framegrabber
bg = getdata(vidobj,numFrames);
if isStack
    bg = ReStackFrames(bg,smallFdims,bigFrameSize,numFrames);
end

% Take the average of all the frames
bg = squeeze(bg);
bg = mean(bg,3);
    
% Save the bgFrame
save([dirname '\bg.mat'], 'bg')
    
% Reset vidobj's parameters
set(vidobj,'FramesPerTrigger',fptOrig);
set(vidobj,'TriggerRepeat',trigRepOrig);

% Restore the previous daq settings
sdaq2.outputSingleScan(present_daq2Vals);
sdaq1.outputSingleScan(digiStates);



    