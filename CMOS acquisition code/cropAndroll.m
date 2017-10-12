% Function to execute a user-defined crop on an image sequence. The first
% 100 frames are displayed as a movie, and then the user positions a box
% over the region on interest and right clicks

% Author: Paul Lebel
% Date: Feb. 2011

function [vid cropcoords] =  cropAndroll(movie, cropsize)

% Convert movie to double (need this to do math with it!)
movie = double(movie);
dims = size(movie);

% Check for cropsize being too large
if (cropsize(1) > dims(1) || cropsize(2) > dims(2))
    error( 'Crop size indicated is larger than image in one or more dimensions')
end


% Reshape image stack to remove extra dimension (often they come from the
% camera as [h w 1 numframes]. Get rid of the 1!
if(numel(dims) == 4)
    movie = shiftdim(reshape(movie,[dims(1) dims(2) dims(4)]));
end

% Create grayscale figure
fig = figure;

for i=1:50
    imagesc(movie(:,:,i));
    axis image; %axis square;
    pause(1/50);
    colormap jet
end

disp('Position the cropping window, and finalize by right-clicking');

rect=rectangle('Position',[.5 0.5 cropsize(1) cropsize(2)],'EdgeColor','r');

% USER FINDS SPOT in left image (Cy3)
%move a box around then
%quit by hitting the right button or pressing x
while (1)
    
[xp,yp,button] = ginput(1);

% Round the starting position 
xp = floor(xp);
yp = floor(yp);

% Check if rectangle is within bounds of image
% if((yp+cropsize(1) > dims(1)) || (xp+cropsize(2) > dims(2) ) || yp < 0 || xp < 0)
%     disp('Move away from the edge!!!');

xp = min(xp,dims(2)-cropsize(2));
xp = max(xp,1);
yp = min(yp,dims(1)-cropsize(1));
yp = max(yp,1);
        
if(button ==3)
    break;
end

% Display crop rectangle
set(rect, 'Position', [xp-1/2, yp-1/2, cropsize(2)+1, cropsize(1)+1],'EdgeColor','r');

end

close(fig)

if nargout >= 1
% Crop the movie to the user-specified dimensions
vid = movie(yp:(yp+cropsize(1)-1),xp:(xp+cropsize(2)-1),:);
end

cropcoords = [yp, yp+cropsize(1), xp, xp+cropsize(2)];
