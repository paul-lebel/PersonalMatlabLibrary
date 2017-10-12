
% Andor settings for fluorescence-----------------------------------------
[ret] = SetFanMode(2);                          %   Turn fan off
[ret]=SetShutter(0, 2, 50, 50);                 %   Close shutter
[ret]=SetTriggerMode(1);                        %   Set trigger mode; 0 for Internal, 6 external start, 10 software
[ret] = SetNumberAccumulations(1);              %   One image per frame
[ret]=SetReadMode(4);                           %   Set read mode; 4 for Image
[ret]=SetAcquisitionMode(5);                    %   Set acquisition mode; 1 for Single Scan, 3 for kinetic, 5 for run till abort
[ret] = SetFrameTransferMode(1);                %   Use frame transfer mode
[ret] = SetVSSpeed(2);                          %   0: 0.3us, 1: 0.5us, 2: 0.9us, 3: 1.7us, 4: 3.3us
[ret] = SetVSAmplitude(0);                      %   Value greater than
[ret] = SetIsolatedCropMode(0,10,10,1,1);       %   De-activate isolated crop
[ret,nospeeds]=GetNumberHSSpeeds(0,0);
[ret] = SetHSSpeed(0,0);                        %   Sets to 10MHz
[ret]=SetPreAmpGain(2);                         %   0: 1; 1: 2.3; 2: 4.9.
[ret,xsize, ysize]=GetDetector;                 %   Get the image size
framesize = xsize*ysize;

%-------------------------------------------------------------------------