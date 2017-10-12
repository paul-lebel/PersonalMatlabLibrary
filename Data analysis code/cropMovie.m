function crop = cropMovie(movie)

dims = size(movie);
waitfor(msgbox('Draw cropping box directly on image frame. Double-click when finished'));
fig = figure; set(0,'CurrentFigure',fig);

% for i=round(linspace(1,dims(3)-1,min(dims(3),200)))
%     imagesc(movie(:,:,i));
%     pause(.05);
% end

proj = mean(movie,3);
imagesc(proj); axis equal;

h = imrect();
cropcoords = wait(h);
cropcoords = round(cropcoords);

x_start = cropcoords(1);
x_width = cropcoords(3);
y_start = cropcoords(2);
y_width = cropcoords(4);

x_end = x_start+x_width-1;
y_end = y_start+y_width-1;


crop = movie(y_start:y_end,x_start:x_end,:);

% for i=round(linspace(1,dims(3)-1,100))
%     imagesc(crop(:,:,i));
%     pause(.03);
% end

delete(fig);