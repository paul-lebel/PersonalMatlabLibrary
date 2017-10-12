% Commands to initialize an Andor Ixon+ and a Mad City Labs PDQ 
% nanopositioning stage for Matlab control. Initialization must be run in 
% advance before data acquisition routines. 

% Assumes the Andor SDK and Matlab adaptor have been installed in the
% directory Matlab/toolbox/Andor

% Assumes the Mad City Labs dll library 'Madlib.dll' is installed in a
% specified folder

% After initialization, the start of data collection should be delayed
% to leave sufficient time for EMCCD cooling.

% Author: Paul Lebel 
% (some commands based on examples provided by Andor and Mad City Labs)


% Andor initialization-----------------------------------------------------
installpath = fullfile(matlabroot,'toolbox','Andor','Camera Files');
addpath(genpath(installpath));

AndorInitialize('');
disp('Initialization status:')
[~,status] = AndorGetStatus

SetFanMode(2)                                               %   Turn fan off (liquid cooling is used)
SetShutter(0, 2, 50, 50);                                   %   Close shutter
CoolerON;                                                   %   Turn on temperature cooler
SetTemperature(-80);                                        %   Set temperature
SetReadMode(4);                                             %   Set read mode; 4 for Image
SetPreAmpGain(1);                                           %   0: 1; 1: 2.3; 2: 4.9
[~,xsize, ysize]=GetDetector;                               %   Get the image size
[ret, circBufsize] = GetSizeOfCircularBuffer();             %   Obtain the number of frames that can be stored in the camera's circular buffer
FreeInternalMemory();

[ret,gstatus]=AndorGetStatus;
while(gstatus ~= 20073)%DRV_IDLE
  pause(1.0);
  disp('Not ready');
  [ret,gstatus]=AndorGetStatus;
end

if ret==20002
    disp('Camera ready!');
else
    disp('Initialization error');
end
% End Andor initialization-------------------------------------------------


% Mad City Labs initialization---------------------------------------------
mclDir = 'C:\Users\Zev Bryant\Documents\MATLAB\Paul\Mad City code\'; % Set this to the directory containing the Mad City Labs library files
hFile = [mclDir 'Madlib.h'];
dllFile = [mclDir 'Madlib.dll'];

% Loads the .dll library
loadlibrary(dllFile,hFile);

% Generates a device handle (this is typically just the number 1)
mcl_handle = calllib('Madlib','MCL_InitHandleOrGetExisting');       

% Center all three stage axes
temp = calllib('Madlib','MCL_SingleWriteN',35,1,mcl_handle);    % Center the x-axis (this device has a 70um x-range)
temp = calllib('Madlib','MCL_SingleWriteN',35,2,mcl_handle);    % Center the y-axis (this device has a 70um y-range)
temp = calllib('Madlib','MCL_SingleWriteN',25,3,mcl_handle);    % Center the z-axis (this device has a 50um z-range)


