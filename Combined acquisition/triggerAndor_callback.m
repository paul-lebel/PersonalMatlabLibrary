function triggerAndor_callback(obj, event, AndorFrameDims, varargin)
%IMAQCALLBACK Display event information for the event.
%
%    IMAQCALLBACK(OBJ, EVENT) displays a message which contains the 
%    type of the event, the time of the event and the name of the
%    object which caused the event to occur.  
%
%    If an error event occurs, the error message is also displayed.  
%
%    IMAQCALLBACK is an example callback function. Use this callback 
%    function as a template for writing your own callback function.
%
%    Example:
%       obj = videoinput('winvideo', 1);
%       set(obj, 'StartFcn', {'imaqcallback'});
%       start(obj);
%       wait(obj);
%       delete(obj);
%
%    See also IMAQHELP.
%

%    CP 10-01-02
%    Copyright 2001-2010 The MathWorks, Inc.
%    $Revision: 1.1.6.8 $  $Date: 2010/12/27 01:13:53 $

% Define error identifiers.



global andorStruct
% global AndorFrameIndex
% global AndorImages
global dualFig
global ax2
global cmosStartTime
% global callback_cmosFramesAcquired
% global andorFid

persistent count prevHandle
count = 1;

errID = 'imaq:imaqcallback:invalidSyntax';
errID2 = 'imaq:imaqcallback:zeroInputs';

switch nargin
    case 0
        error(message(errID2));
    case 1
        error(message(errID));
    case 2
        if ~isa(obj, 'imaqdevice') || ~isa(event, 'struct')
            error(message(errID));
        end   
        if ~(isfield(event, 'Type') && isfield(event, 'Data'))
            error(message(errID));
        end
end

% Determine the type of event.
EventType = event.Type;

% Determine the time of the error event.
EventData = event.Data;
EventDataTime = EventData.AbsTime;


% Get all new images from the Andor
[ret, first, last] = GetNumberNewImages();
 nFrames = last-first+1
 
 % Record the elapsed time since triggering the CMOS. Hopefully this can
% help with post-synchronization.
andorStruct.time(andorStruct.frameIndex+nFrames) = etime(EventDataTime,cmosStartTime);

% Record the number of CMOS frames that have been acquired at this moment
% (at this moment where we also download Andor frames). Each time this
% callback is executed we generate a synchronization point. 
andorStruct.cmosFramesAcquired(andorStruct.frameIndex+nFrames) = obj.FramesAcquired;

nPixels = andorStruct.dims(1)*andorStruct.dims(2)*nFrames;
[grabret, imagedata, validfirst, validlast] = GetImages16(first,last,nPixels);

% Check imaq memory usage
out = imaqmem;
mem_left = out.FrameMemoryLimit - out.FrameMemoryUsed;
disp(['Image memory left = ' num2str(round(mem_left/1000000)) ' MB']);

if nFrames > 0
andorStruct.images(:,:,andorStruct.frameIndex:(andorStruct.frameIndex+nFrames-1)) = ...
    reshape(imagedata,[AndorFrameDims(2) AndorFrameDims(1) nFrames]);

fwrite(andorStruct.fid,andorStruct.images(:,:,andorStruct.frameIndex:(andorStruct.frameIndex+nFrames-1)),'uint16');
set(0,'CurrentFigure',dualFig);
set(dualFig,'CurrentAxes',ax2);
tempFrame = rot90(mean(andorStruct.images(:,:,andorStruct.frameIndex:(andorStruct.frameIndex +nFrames-1)),3),3);

if count ==1
prevHandle = imagesc(tempFrame);  
else
    set(prevHandle,'CData',tempFrame);
end

axis image;
text(-1,-1,num2str(max(tempFrame(:))));
drawnow;

andorStruct.frameIndex = andorStruct.frameIndex + nFrames;

disp(['Acquired ' num2str(andorStruct.frameIndex) ' Andor frames']);
end

count = count + 1;
