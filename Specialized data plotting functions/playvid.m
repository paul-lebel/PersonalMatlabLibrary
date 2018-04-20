% Play image video
% inputs:
% 'movie' is a 3 (or 4) dimensional array containing frames of a movie
% 'framerange' is a vector containing the frame indices to be displayed
% 'fps' is the number of frames per second to display. Note that the
% display speed saturates because Matlab graphics functions are very slow.


function playvid(movie, framerange, fps, scale)

movie = squeeze(movie);

nArgs = nargin();
if nArgs < 2
    framerange = [1 : size(movie,3)];
end
if nArgs < 3
    fps = 30;
end
if nArgs < 4
    scale(1) = min(min(min(movie(:,:,framerange(1):framerange(end)))));
    scale(2) = max(max(max(movie(:,:,framerange(1):framerange(end)))));
end

fig = figure;
axis square
axis equal
colormap gray;

    set(0,'CurrentFigure',fig);
    
    h = imagesc(movie(:,:,framerange(1)),scale);
    i=0;
    while (i < framerange(end)) && h.isvalid
        i = i+1;
        if h.isvalid
            h.CData = movie(:,:,framerange(i)); 
        else
            break;
        end
        text(-3,-3,num2str(i));
        pause(1/fps);
    end
end
