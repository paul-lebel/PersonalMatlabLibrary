% My preview

function previewStack_10(vid,bgFlag, bigFsize)
% imaqmem(1500000000)
crop = get(vid,'ROIPosition');
dims(1) = crop(3);
dims(2) = crop(4);
dims = circshift(dims,[0 1]);
dims(1) = dims(1)/bigFsize;

if bgFlag ==1
    bg = int16(takeBG(vid,100,'C:\Users\labuser\Dropbox (Berkeley Lights Inc.)\BLI Share\Optics\Cameras\Lebel camera testing\Jan 6th Testing\Orca Flash 4.0 LT',bigFsize,1));
else
    bg = int16(zeros(dims));
end

stop(vid)
repeat = get(vid,'TriggerRepeat');
fPt = get(vid,'FramesPerTrigger');
set(vid,'FramesPerTrigger',inf)

fig = figure;

stop(vid); start(vid); pause(0.02);

while ishandle(fig)
    
    
    while(get(vid,'FramesAvailable') < 1)
        pause(0.001);
    end
    
    data = int16(peekdata(vid,1));
    frame = data(1:dims(1),:);
    flushdata(vid);
    set(0,'CurrentFigure',fig);
    imagesc(frame-bg) %,[0 1023]);
    colormap(jet); colorbar;
    axis equal;
    drawnow;
    pause(.05);
end

stop(vid)
flushdata(vid)
set(vid,'FramesPerTrigger',fPt);
set(vid,'TriggerRepeat',repeat);

disp('Preview done')