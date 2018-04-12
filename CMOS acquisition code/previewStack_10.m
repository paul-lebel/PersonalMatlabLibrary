% My preview

function previewStack_10(vid,bgFlag, bigFsize)
% imaqmem(1500000000)
flushFreq = 50;
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
repeat = get(vid,'TriggerRepeat');
fPt = get(vid,'FramesPerTrigger');
set(vid,'FramesPerTrigger',inf)

fig = figure;
im = imagesc(bg);
colormap gray; axis equal;

start(vid);
count = 0;
while ishandle(fig)
    
    
%     while(get(vid,'FramesAvailable') < 1)
%         pause(0.001);
%     end
    if vid.FramesAvailable > 0
        data = int16(peekdata(vid,1));
        frame = data(1:dims(1),:);
    end
    
    % Flush data once in a while to clear buffer
    if ~mod(count,flushFreq)
        flushdata(vid);
    end
    
    im.CData = frame - bg;
    drawnow;
    pause(.05);
end

stop(vid);
flushdata(vid);
set(vid,'FramesPerTrigger',fPt);
set(vid,'TriggerRepeat',repeat);

disp('Preview done')