% Set up a daq object for facilitating synchronized operation of the
% Mikrotron CMOS camera with the Andor EMCCD. This code configures the DAQ
% system to use the CMOS strobe output as a clock with which to drive
% analog and digital operations. Doing so allows us to have exactly
% synchronized datapoints for Andor camera exposure, laser intensity
% detection, shutter operation, etc. 

% This script is called by 'combinedSpool.m', and shares variable names
% with it as well.

% Create a daq object


% if exist('s_main') 
% delete(s_main);
% clear s_main
% end

global s_main lockInfo

delete(s_main); 
clear -global s_main;
delete(s_lock);
clear -global s_lock;

lockInfo.errSum = 0;
lockInfo.memoryLength = 20000;
lockInfo.logging = 0;
lockInfo.zCurrent = 25*ones(lockInfo.memoryLength,1);
lockInfo.zCurrent(1) = readZ(1);
lockInfo.zPSDmean = zeros(lockInfo.memoryLength,1);
lockInfo.n = 1;

s_main = daq.createSession('ni');

% Add analog input channels 
s_main.addAnalogInputChannel('dev2','ai0','Voltage');   % IR beam intensity
s_main.addAnalogInputChannel('dev2','ai1','Voltage');   % IR beam pos
% s_main.addAnalogInputChannel('dev2','ai2','Voltage');   % Green beam intensity
% s_main.addAnalogInputChannel('dev2','ai3','Voltage');   % Green beam pos

% Add digital channels
% s_main.addDigitalChannel('dev2','port0/line2','OutputOnly'); % [Connect Andor's 'Expose' input to line7]
s_main.addCounterOutputChannel('dev2','ctr0','PulseGeneration');  % Counter output to trigger the Andor
s_main.Channels(3).Frequency = AndorRate;
% Add the CMOS strobe as a clock connection
% cmosClock = s_main.addClockConnection('external','dev2/PFI5','scanClock'); % [Connect CMOS strobe to PFI5]
% triggerConn = s_main.addTriggerConnection('external','dev2/PFI5','StartTrigger'); % [Also relies on strobe connected to PFI5]

% Add a listener for focus lock
% lh = s_lock.addlistener('DataAvailable', @lockOnly);

lh = s_main.addlistener('DataAvailable', @lockOnly);
lockInfo.P = .5; % Controller proportional gain parameter
lockInfo.I = .05; % Controller integral gain parameter
lockInfo.D = 0; % Controller differential parameter

cmosdT = 1/cmosFrameRate;
driveTime = cmosdT:cmosdT:cmosdT*cmosFrameRate;
% andorDriveSignal = 0.5*(1 + square(2*pi*AndorRate*driveTime))';

% lh = s_main.addlistener('DataRequired',@(src,event) src.queueOutputData(andorDriveSignal));

% s_main.queueOutputData(andorDriveSignal);
s_main.Rate = cmosFrameRate;
s_main.DurationInSeconds = nCMOSFrames/cmosFrameRate + 2;
s_main.NotifyWhenDataAvailableExceeds = round(s_main.Rate);

% s_main.TriggersPerRun = 1;  % Need to set this because the trigger signal is a clock
% s_main.ExternalTriggerTimeout = 10; % Arbitrary

% data = s_main.startForeground();
