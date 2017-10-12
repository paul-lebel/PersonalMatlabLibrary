function stopAndor_callback(obj, event, varargin)

disp('CMOS stopped');
ret = AbortAcquisition();
if ret == 20002
    disp('Andor stopped');
SetShutter(0, 2, 50, 50);           

set(obj,'TimerFcn',[]);
set(obj,'StopFcn',[]);
set(obj,'FramesAcquiredFcn',[]);

end