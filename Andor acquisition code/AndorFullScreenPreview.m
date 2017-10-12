
% Do not change------------------------------------------------------------
[ret] = SetIsolatedCropMode(0,10,10,1,1);       %   Turn off isolated crop
[ret]=SetAcquisitionMode(5);                    %   Set acquisition mode; 1 for Single Scan, 3 for kinetic, 5 for run till abort
SetFrameTransferMode(1);                %   Use frame transfer mode
SetTriggerMode(0);        %   Set trigger mode: 0 for Internal, 1 for External, 6 for External start, 7 for External Exposure ...
chipx = 512; chipy = 512;
if ~exist('AndorCropVec')
    AndorCropVec = [1,512,1,512];
end
SetImage(1,1,AndorCropVec(1),AndorCropVec(2),AndorCropVec(3),AndorCropVec(4)); % AndorCropVec should be obtained from 'getAndorCropVec'
%--------------------------------------------------------------------------


% Set these parameters as desired------------------------------------------
SetEMCCDGain(2);  
SetExposureTime(0.01);                   %   
%--------------------------------------------------------------------------

xsize = AndorCropVec(2)-AndorCropVec(1) + 1;
ysize = AndorCropVec(4)-AndorCropVec(3) + 1;
keep = 1;
[ret,Exposure, Accumulate, Kinetic]=GetAcquisitionTimings;    %   Get acquisition setting

imagedata = zeros(xsize*ysize,1);
datasquare = zeros(ysize,xsize);


prev = figure('Position',[50 200 700 650])
colorbar; colormap gray; axis square; axis equal;
set(gcf,'KeyPressFcn','keep=0');

 [ret]=SetShutter(0, 1, 50, 50);                 %   Open the shutter
 StartAcquisition;     
while(keep == 1)
    [ret imagedata]  = GetMostRecentImage(xsize*ysize);
    datasquare = rot90(reshape(imagedata,[xsize ysize]),3);
    set(0,'CurrentFigure',prev);
    if exist('back','var')
        datasquare=double(datasquare)-back;
    end
    imagesc(datasquare); axis image; colormap jet;
    text(-2,0,num2str(max(imagedata)));
    drawnow;
    pause(.01);
end


[ret] = AbortAcquisition()
[ret]=SetShutter(0, 2, 50, 50);                 %   Close the shutter
