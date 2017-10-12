
% get Andor cropVec. Make sure there is an open figure window produced by a
% full-chip andor preview

AndorCropVec = [1,512,1,512];
SetImage(1,1,AndorCropVec(1),AndorCropVec(2),AndorCropVec(3),AndorCropVec(4)); % AndorCropVec should be obtained from 'getAndorCropVec'
xsize = AndorCropVec(2)-AndorCropVec(1) + 1;
ysize = AndorCropVec(4)-AndorCropVec(3) + 1;

fig = figure;
returnNFrames(xsize,ysize,100,1);

h = imrect();
cropcoords = wait(h);
cropcoords = round(cropcoords);

x_start = cropcoords(1);
x_width = cropcoords(3);
y_start = cropcoords(2);
y_width = cropcoords(4);

x_end = x_start+x_width-1;
y_end = y_start+y_width-1;

AndorCropVec = [(512-x_end),(512-x_start),y_start,y_end];

delete(fig);