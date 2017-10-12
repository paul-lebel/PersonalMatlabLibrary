

% A script to acquire an accurate length measurement of a DNA tether. The
% script moves the piezo stage in a sawtooth fashion, acquiring a short
% video each time. The movie frame should contain both the tether of
% interest as well as a stuck magnetic bead as a fiducial. The repeated
% sweeping action of the stage allows multiple differential height
% measurements of the tether, minimizing drift.

% Author: Paul Lebel
% Date: January 18th, 2012

% Comment out if piezo is already initialized
% initPiezo;

% Initialize vector to store the waveform read data, and a time vector to
% define the waveform load data.
datavec = zeros(1,5000);
dt = .002;
t = dt:dt:5000*dt;

% Waveform load data
waveform = 20+ linspace(0,10,5000);

% These waveform library functions require pointers to their variables
pdata = libpointer('doublePtr',datavec);
pwaveform = libpointer('doublePtr',waveform);

% Set up the load waveform on the z axis with 2ms command rate
temp = calllib('Madlib','MCL_Setup_LoadWaveFormN',3,5000,2,pwaveform,mcl_handle);

% Prepare the camera for 10 triggered acquisitions of 1000 frames each
flushdata(previd);
stop(previd);
imaqmem(5E9);
triggerconfig(previd, 'Manual');
set(previd,'triggerRepeat',9);
set(previd,'FramesperTrigger',1000);

% Starts acquisition, but logging is not on until the trigger occurs.
start(previd);

% deltaT stores the total sweep duration
deltaT = 0;

for i=1:10
    
    t1 = clock;
    
    disp(['starting sweep ' num2str(i)])
    % Trigger stage motion
    temp = calllib('Madlib','MCL_Trigger_LoadWaveFormN',3,mcl_handle);

    % pause for 50ms to allow for initial motion to settle
    pause(.05);
    
    trigger(previd);
    disp('Triggered camera');
    
    % Wait for camera to finish
    while(islogging(previd))
        pause(.001);
    end
    
    % Make sure stage is finished also, by ensuring the total elapsed time
    % is greater than the waveform duration
    while (deltaT < max(t))
        t2 = clock;
        deltaT = t2(6)-t1(6);
        pause(.01);
    end
    
    
    
    disp(['Done sweep ' num2str(i) ' in ' num2str(deltaT) ' seconds']);
    disp(' ');
end

    [data time] = getdata(previd,10000);
    data = data(:,:,1,:);
data = squeeze(data);

