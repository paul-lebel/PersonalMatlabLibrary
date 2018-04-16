% My preview

function previewStack_10(vid,bgFlag, bigFsize, diffFlag)
% imaqmem(1500000000)
flushFreq = 50;
stop(vid); start(vid); stop(vid);
crop = get(vid,'ROIPosition');
dims(1) = crop(3);
dims(2) = crop(4);
dims = circshift(dims,[0 1]);
dims(1) = dims(1)/bigFsize;

if bgFlag ==1
    bg = int16(takeBG(vid,100,pwd,bigFsize,1));
else
    bg = int16(zeros(dims));
end

stop(vid);
frame = bg;
lastFrame = frame;

repeat = get(vid,'TriggerRepeat');
fPt = get(vid,'FramesPerTrigger');
set(vid,'FramesPerTrigger',inf)

fig = figure;
ax1 = subplot(1,4,1:3);
ax2 = subplot(1,4,4);
im = imagesc(ax1,bg);
colormap gray; axis equal;

count = 0;
stdVec = zeros(10000,1);
fa = 0;
start(vid);

while ishandle(fig)
    
    count = count + 1;
    while(vid.FramesAcquired <= fa)
        pause(0.001);
    end
    
    fa = vid.FramesAcquired;
    
        data = int16(peekdata(vid,1));
        frame = data(1:dims(1),:);
    
    % Flush data once in a while to clear buffer
    if ~mod(count,flushFreq)
        flushdata(vid);
    end
    
    if diffFlag
        im.CData = frame - lastFrame;
    else
        im.CData = frame - bg;
    end
    
    stdVec(count) = std(double(frame(:)));
    plot(ax2,stdVec(max(1,count-200):count)); 
%     ylim([800 1200]);
    lastFrame = frame;
    drawnow;
    pause(.001);
end

stop(vid);
flushdata(vid);
set(vid,'FramesPerTrigger',fPt);
set(vid,'TriggerRepeat',repeat);

disp('Preview done')