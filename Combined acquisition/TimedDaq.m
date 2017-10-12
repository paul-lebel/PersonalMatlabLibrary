s= daq.createSession('ni');
s.addAnalogInputChannel('Dev1', 'ai0', 'Voltage');
lh = s.addlistener('DataAvailable', @plotData);

% Realtime acquisition loop interfacing with the Mikrotron camera at high
% frame rates. This script acquires data from the Bitflow framegrabber
% using multiple frames per buffer (the bitflow framegrabber 'thinks' the
% camera frame size is actually 100 frames tall).

% This code sets the grabbers's frames per trigger value to infinity, so the
% camera simply streams a flow of data to its indefinitely and we grab it as needed. The
% timed loop ensures no data is missed

% The user is prompted to choose a number of crops to save, and whether to
% save these data to memory and/or to disk. For very long movies, you can
% save to disk only, limited only be hard drive space.

% Author: Paul Lebel
% April 2011

% Clear user input variables
clear dd dd2 dm dm2

% Define a start path to my data folder
start_path = 'F:\Paul_Data\Jan.2012';

%-------User inputed parameters - changed frequently-----------------------
prompt = {
    'Description'
    'Number of crops (1 or 2)'
    'Crop size [h w]'
    'Frame rate [Hz]'
    'Total frames?'
    'Enzyme?'
    'Iris setting [mm]'
    'Magnet height [mm] from coverslip'
    'Laser wavelength [nm]'
    '# of magnetic beads'
    'Stage feedback'
    
    };

fields = {
    'description'
    'numCrops'
    'cropSize'
    'FrameRate'
    'totalFrames'
    'Enzyme'
    'irisDiam'
    'magnetHeight'
    'laserWavelength'
    'numMags'
    'stageFeedback'
    
    };

isNumeric = [0 1 1 1 1 0 1 1 1 1 0];
numInds = find(isNumeric==1);
info = inputdlg(prompt, 'Enter movie parameters');

% Convert numeric entries from text to numbers
for i=1:numel(numInds)
    info{numInds(i)} = str2num(info{numInds(i)});
end
% Convert info cell to struct
info = cell2struct(info,fields);

info.filename = 'left.dat';
if info.numCrops == 2
    info.filename2 = 'right.dat';
end

%--------------------------------------------------------------------------


%-------Script parameters - should not change on a daily basis-------------
% Set some bitflow parameters
b= imaqmem('FrameMemoryLimit');
set(vid,'FramesPerTrigger',inf);
set(vid,'TriggerRepeat',0);
set(getselectedsource(vid),'BuffersToUse',100);

bigFperLoop = 100;
% Warning: this value of 100 for bigFrameSize is hard-coded in several
% places elsewhere in the code.
bigFrameSize = 100;
count = 1; fA = 0;
maxcount = 1+floor(info.totalFrames/(bigFrameSize*bigFperLoop));

% Get small frame dimensions
temp = get(vid,'VideoResolution');
smallFdims(1) = temp(2)/bigFrameSize;
smallFdims(2) = temp(1); clear temp;

% Memory devoted to image acquisition toolbox. 8 bytes/pixel. 4 is an
% arbitrary safety factor
imaqmem(4*prod(smallFdims)*8*bigFperLoop*bigFrameSize);
%--------------------------------------------------------------------------

% Set the duration of the analog input acquisition
s.DurationInSeconds = round(info.totalFrames/info.FrameRate + .5);
s.Rate = info.FrameRate;
s.NotifyWhenDataAvailableExceeds = round(s.Rate*s.DurationInSeconds);


% Pre-allocate data buffers for speed
databuffer = zeros(100*smallFdims(1),smallFdims(2),1,bigFperLoop);
smallFbuff = zeros(smallFdims(1),smallFdims(2),bigFperLoop*100);
remainder = zeros(1,round(info.totalFrames/(bigFperLoop*bigFrameSize)));
looptime = remainder;
imframe = zeros(smallFdims);
time = cell(1,maxcount);

% Get crops
coords = prevCrop(vid,smallFdims,info.numCrops,info.cropSize);

% Assign the crop coords array to the info struct
info.cropcoords = coords;

dd = input('Save crop 1 data to disk? (1/0)');
dm = input('Log crop 1 data to memory? (1/0)');

% Create directory for this movie, and put the info structure in there then
% create the movie file itself
if dd
    dirname = uigetdir(start_path,'Select directory to save');

    [~, ~, ~, hour, min, sec] = datevec(now);
    subdirname = strcat(dirname,'\',num2str(hour),'_',num2str(min),'pm');
    mkdir(subdirname);
    infoname = strcat(subdirname,'\',info.filename,'_info.mat');
    save(infoname,'info');

    % create file to save
    pathname = strcat(subdirname, '\' ,info.filename);
    fid1 = fopen(char(pathname),'w');
end

% Allocate memory chunk for crop 1
if dm
    datalog1 = zeros(info.cropSize(1),info.cropSize(2),info.totalFrames);
end

if info.numCrops==2
    
    %     dd2 = input('Save crop 2 data to disk? (1/0)');
    dd2 = dd; % For now, saving either none or both crops
    
    dm2 = input('Log crop 2 data to memory? (1/0)');
    if dd2
        % open file to save
        %         dirname2 = uigetdir('Select directory to save');
        pathname2 = strcat(subdirname, '\' ,info.filename2);
        fid2 = fopen(char(pathname2),'w');
    end
    
    if dm2
        datalog2 = zeros(info.cropSize(1),info.cropSize(2),info.totalFrames);
    end
    
    
end


stop(vid);
flushdata(vid);



% Capture a background frame and save it to disk
bgFrame = takeBG(vid,1000,subdirname,1);

% Start laser intensity acquisition
s.startBackground;
pause(.25);

% Lights, camera, action!
start(vid);

%--------------------------------------------------------------------------
% Realtime acquisition loop.
%--------------------------------------------------------------------------
while(count<maxcount)
    tic;
    
    
    % Compute the actual frame indices for this loop (litInd = start,
    % bigInd  = end)
    litInd = 1+(count-1)*100*bigFperLoop;
    bigInd = count*100*bigFperLoop;
    
    % Wait for requested number of frames, then immediately grab them
    
    while(get(vid,'FramesAvailable') < bigFperLoop)
        pause(.0001);
    end
    
    
    % Grab big frames
    [databuffer temptime] = getdata(vid,bigFperLoop);
    %    time{count} = temptime;
    %      remainder(count) = toc;
    
    % Chop the stack of big frames into little ones
    smallFbuff = ReStackFrames(databuffer,smallFdims,100,100);
    
    
    % Update preview display
        imframe = smallFbuff(:,:,1);
    imagesc(imframe-bgFrame); colormap gray; axis image;
    
    % Log data to memory and disk, according to user choices dd,dm,dd2,dm2
    if dm
        datalog1(:,:,litInd:bigInd) = smallFbuff(coords(1,1):coords(1,2)-1, ...
            coords(1,3):coords(1,4)-1,:);
    end
    
    if dd
        fwrite(fid1,smallFbuff(coords(1,1):coords(1,2)-1, ...
            coords(1,3):coords(1,4)-1,:),'double');
    end
    
    
    
    if info.numCrops==2
        
        if dd2
            fwrite(fid2,smallFbuff(coords(2,1):coords(2,2)-1, ...
                coords(2,3):coords(2,4)-1,:),'double');
        end
        if dm2
            datalog2(:,:,litInd:bigInd) = smallFbuff(coords(2,1):coords(2,2)-1, ...
                coords(2,3):coords(2,4)-1,:);
        end
    end
    
    
    %     job1 = batch(@callGsolve,{datalog1(:,:,litInd:bigInd)}, 'configuration', 'local', ...
    %      'matlabpool', 2);
    %
    %     job2 =
    
    
    
    % Display acquisition info
    looptime(count) = toc;
    fprintf('%i frames acquired \n',bigInd);
    fprintf('Looptime = %3.2d s \n',looptime(count));
    %     fprintf('Waited = %3.2d s for frames \n \n',remainder(count));
    count = count+1;
    
    
end



% Tidy things up: stop acquisition, close data files, clear temporary
% buffers
stop(vid)
flushdata(vid)

clear databuffer smallbuff1 smallbuff2 smallFbuff

if dd
    fclose(fid1);
end

if info.numCrops ==2
    if dd2
        fclose(fid2);
    end
end

% s.stop;
% delete(lh);