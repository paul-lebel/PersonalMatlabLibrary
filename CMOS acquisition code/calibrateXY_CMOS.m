
% Script to acquire a quick magnification calibration by stepping the piezo
% stage through a 2D array of positions, taking images of a stuck particle
% at each stepping point.

%Piezo stage should be initialized and set somewhere near the
% middle of the range of motion (or just not at the edges).

cropsize = [25 50];

xPos = readX(mcl_handle);
yPos = readY(mcl_handle);

nFramesPerXY = 50;
set(vid,'FramesPerTrigger',nFramesPerXY);
set(vid,'TriggerRepeat',0);

bg = double(takeBG(vid,50,'F:\bgframe',0,0));
bg = bg(:,61:110);

dx = 0.1; % um
dy = 0.1; % um
nSteps = 5;

xrange = xPos + [dx:dx:dx*nSteps];
yrange = yPos + [dy:dy:dy*nSteps];

[X Y] = meshgrid(xrange,yrange);

imagedata = cell(size(X));
stats = zeros(nFramesPerXY,6,nSteps,nSteps);

% [ret]=SetShutter(0, 1, 50, 50);                 %   Open the shutter

for k=1:10
    
    piezoX(1,X(1,1));
    piezoY(1,Y(1,1)); pause(1);
    
    % Step the stage, acquire 50 images per position, do the fitting
    for i=1:nSteps
        disp(i)
        for j=1:nSteps
            piezoX(1,X(i,j));
            piezoY(1,Y(i,j));
            pause(.25);
            start(vid);
            while(isrunning(vid))
                pause(.01);
            end
            temp = getdata(vid,nFramesPerXY);
            stop(vid); flushdata(vid);
            
            imagedata{i,j} = bsxfun(@minus,squeeze(double(temp(:,61:110,1,:))),bg);
            stats(:,:,i,j) = gsolve2d(reshape(imagedata{i,j},[prod(cropsize)*nFramesPerXY,1]),[cropsize(2) cropsize(1)]);
        end
    end
        
    
    xm = squeeze(mean(stats(:,3,:,:),1));
    ym = squeeze(mean(stats(:,4,:,:),1));
    
    xAll = squeeze(stats(:,3,:,:));
    yAll = squeeze(stats(:,4,:,:));
    
    deltaXm = diff(mean(xm,1));
    deltaYm = diff(mean(ym,2));
    xmBar = mean(deltaXm);
    ymBar = mean(deltaYm);
    
    xMagnification(k) = abs(1000*dx/xmBar)
    yMagnification(k) = abs(1000*dy/ymBar)
end

piezoX(1,xPos);
piezoY(1,yPos);

