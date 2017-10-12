% My preview

function previewStack(vid,bgFlag, bigFsize)
% imaqmem(1500000000)
dims = get(vid,'videoResolution');
dims = circshift(dims,[0 1]);
dims(1) = dims(1)/bigFsize;

if bgFlag ==1
    bg = takeBG(vid,100,'F:\bgFrame',bigFsize,1);
else
    bg = zeros(dims);
end

bg = int16(bg);


stop(vid)
repeat = get(vid,'TriggerRepeat');
fPt = get(vid,'FramesPerTrigger');
set(vid,'FramesPerTrigger',inf)

fig = figure;

stop(vid); start(vid); pause(0.02);

while(ishandle(fig))
    
    while(get(vid,'FramesAvailable') < 1)
        pause(0.001);
    end
    
    data = peekdata(vid,1);
    frame = int16(data(1:dims(1),:));
    flushdata(vid);
    
    imagesc(frame-bg);
    colormap(jet); colorbar;
    axis tight equal
    pause(.05);
    
end

stop(vid)
flushdata(vid)
set(vid,'FramesPerTrigger',fPt);
set(vid,'TriggerRepeat',repeat);

disp('Preview done')