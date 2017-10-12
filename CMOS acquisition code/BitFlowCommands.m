% A bunch of bitflow commands

% 8 bit full frame
vid = videoinput('bitflow',1,'Mikrotron-MC1310-1280x1024-E10-FreeRun.r64')

% Compressed (stacked) frames
vid = videoinput('bitflow',1,'Mikrotron-Eos-160x25-STACK10bit-4tap-FreeRun.r64')
vid = videoinput('bitflow',1,'Mikrotron-Eos-128x32-STACK10bit-4tap-FreeRun.r64')
vid = videoinput('bitflow',1,'Mikrotron-Eos-160x25-STACK8bit-10tap-FreeRun.r64')

% Subregion frames
vid = videoinput('bitflow',1,'Mikrotron-Eos-160x25-10bit-4tap-FreeRun.r64')
vid = videoinput('bitflow',1,'Mikrotron-Eos-160x25-8bit-10tap-FreeRun.r64')

% 10 bit full frame. Doesn't work yet!
% vid = videoinput('bitflow',1,'Mikrotron-MC1310-1280x1024-10bit_Full_frame_FreeRun.r64');

% 640x400 8-bit
vid = videoinput('bitflow',1,'Mikrotron-Aathi-640x400-E10-FreeRun.r64')
% 640x400 10 bit 
vid = videoinput('bitflow',1,'Mikrotron-Aathi-640x400-10bit-FreeRun.r64')

% 400x120 Can go 9.6 kHz
vid = videoinput('bitflow',1,'Mikrotron-Aathi-400x120-E10-FreeRun.r64')


set(getselectedsource(vid),'BuffersToUse',50);



start(vid)
set(vid,'FramesPerTrigger',500);
set(vid,'TriggerRepeat',0);

set(getselectedsource(vid),'BuffersToUse',5)
stop(vid)
imaqmem(12000000000)
[data, time, metadata] = getdata(vid);
flushdata(vid);