% Play image video
% inputs:
% 'movie' is a 3 (or 4) dimensional array containing frames of a movie
% 'framerange' is a vector containing the frame indices to be displayed
% 'fps' is the number of frames per second to display. Note that the
% display speed saturates because Matlab graphics functions are very slow.


function playvid(movie, framerange, fps)

nArgs = nargin();
if nArgs == 1
    framerange = [1 : size(movie,3)];
    fps = 30;
end

fig = figure;

axis square
colormap(jet)
axis equal

mi = min(min(min(movie(:,:,framerange(1):framerange(end)))));
ma = max(max(max(movie(:,:,framerange(1):framerange(end)))));

if(numel(size(movie))==4)
    set(0,'CurrentFigure',fig);
    imagesc(movie(:,:,1,framerange(1)));
    
    for i= 1:length(framerange)
        image(movie(:,:,:,framerange(i))); colormap gray;
        %         axis equal; colorbar;
        if(isempty(findall(0,'Type','Figure')))
            break;
        end
        
        pause(1/fps);
    end
    
else if(numel(size(movie))==3)
        set(0,'CurrentFigure',fig);
        
        h = imagesc(movie(:,:,framerange(1)));
        
        for i= 1:length(framerange)
                        imagesc(movie(:,:,framerange(i))); colormap gray;
%             set(h,'CData',movie(:,:,framerange(i)));
            
            text(-3,-3,num2str(i));
            %             disp(i)
            axis equal;
            %             colorbar;
            
            
            pause(1/fps);
            if(isempty(findall(0,'Type','Figure')))
                break;
            end
        end
    end
    
end