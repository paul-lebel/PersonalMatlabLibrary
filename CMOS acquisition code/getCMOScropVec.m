% get a crop vector by  Make sure there is an open figure window produced by a
% full-chip andor preview


h = imrect();
cropcoords = wait(h);
cropcoords = round(cropcoords);

x_start = cropcoords(1);
x_width = cropcoords(3);
y_start = cropcoords(2);
y_width = cropcoords(4);

x_end = x_start+x_width-1;
y_end = y_start+y_width-1;

cmosCropVec = [y_start,y_end,x_start,x_end];

