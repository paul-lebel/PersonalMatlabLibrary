cropsize = [500 500];

[ret]=SetAcquisitionMode(5);                    %   Set acquisition mode; 1 for Single Scan, 3 for kinetic, 5 for run till abort
[ret] = SetFrameTransferMode(1);
[ret] = SetIsolatedCropMode(1,cropsize(1),cropsize(2),1,1);
[ret]=SetTriggerMode(0);                        %   Set trigger mode; 0 for Internal, 6 external start, 10 software
[ret]=SetExposureTime(0.001);
[ret]=SetEMCCDGain(0);                          % 

xsize = cropsize(1);
ysize = cropsize(2);
keep = 1;

imagedata = zeros(xsize*ysize,1);
datasquare = zeros(ysize,xsize);

prev = figure('Position',[50 600 400 350])
colorbar; colormap jet; axis square; axis equal;
[ret,Exposure, Accumulate, Kinetic]=GetAcquisitionTimings;    %   Get acquisition setting


set(gcf,'KeyPressFcn','keep=0');

 [ret]=SetShutter(0, 1, 50, 50);              
 StartAcquisition;   
  
while(keep == 1)
    [ret imagedata]  = GetMostRecentImage(xsize*ysize);
    datasquare = reshape(imagedata,[cropsize(2) cropsize(1)]);
    imagesc(log(abs(rot90(double(datasquare),3)))); axis image;
    text(-.5,.5,num2str(max(imagedata)));
    pause(.01);
end


[ret] = AbortAcquisition()
[ret]=SetShutter(0, 2, 50, 50);                 %   Close the shutter
