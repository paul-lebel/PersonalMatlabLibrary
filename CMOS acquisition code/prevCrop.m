




function cropCoords = prevCrop(vid,framedims,w,cropsize,bigFrameSize)

numBGframes = 1000;

% Store user's vid acq values to reset them later
fpt = get(vid,'FramesPerTrigger');
tr = get(vid,'TriggerRepeat');

% Verify correct input
if (numel(w)~=1)
    error('Please input a scalar value');
end

%------------------------
% Take a short preview video, and query user input for crop(s)
set(vid,'FramesPerTrigger',round(numBGframes/bigFrameSize));
set(vid,'TriggerRepeat',0);
start(vid);

% Wait for the acquisition to finish
while(isrunning(vid))
    pause(.01);
end

% Get the preview data
previewData = getdata(vid);
previewData = double(squeeze(previewData));
%------------------------
% Unravel the stacked image frames, and allow the user to select crop(s)
previewData = ReStackFrames(previewData, framedims, bigFrameSize,floor(numBGframes/bigFrameSize));

if floor(w) >=1
    [temp cropCoords(1,:)] = cropAndroll(previewData,cropsize);
end

if floor(w) >=2
    [temp cropCoords(2,:)] = cropAndroll(previewData,cropsize);
end

if floor(w) >=3
    [temp cropCoords(3,:)] = cropAndroll(previewData,cropsize);
end

if floor(w) >=4
    [temp cropCoords(4,:)] = cropAndroll(previewData,cropsize);
end

set(vid,'FramesPerTrigger',fpt);
set(vid,'TriggerRepeat',tr);