% Set up the Andor camera for highspeed data acquisition

% Author: Paul Lebel
% Date: April 2012

installpath = fullfile(matlabroot,'toolbox','Andor','Camera Files');
addpath(genpath(installpath));
% cd (installpath);

AndorInitialize('');
disp('Initialization status:')
[ret,status] = AndorGetStatus

SetFanMode(2);                              %   Turn fan off
SetShutter(0, 2, 50, 50);                   %   Close shutter
CoolerON;                                   %   Turn on temperature cooler
SetTemperature(-80);                        %   Set temperature
SetTriggerMode(0);                          %   Set trigger mode; 0 for Internal, 6 external start, 10 software
SetNumberAccumulations(1);                  %   One image per frame
SetReadMode(4);                             %   Set read mode; 4 for Image
SetAcquisitionMode(5);                      %   Set acquisition mode; 1 for Single Scan, 3 for kinetic, 5 for run till abort
SetFrameTransferMode(1);                    %   Use frame transfer mode
SetVSSpeed(1);                              %   Sets to 0.5us
SetVSAmplitude(1);                          %   Helps for fast shift speeds
[ret,nospeeds]=GetNumberHSSpeeds(0,0);
SetHSSpeed(0,0);
SetPreAmpGain(1);                           %   0: 1; 1: 2.3; 2: 4.9
SetEMGainMode(3);
SetEMCCDGain(3);                            %   Set this manually later
SetExposureTime(0.001);                     %   Exposure determines framerate
[ret,xsize, ysize]=GetDetector;             %   Get the image size
[ret,Exposure, Accumulate, Kinetic]=GetAcquisitionTimings;    %   Get acquisition setting
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