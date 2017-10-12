
% Script to acquire a quick magnification calibration by stepping the piezo
% stage through a 2D array of positions, taking images of a stuck particle
% at each stepping point.

% Requires the isolated crop mode already be set up, etc. etc. Basically if
% 'AndorPreview.m' shows you the correct starting point for the scan, it is 
% sufficient. The piezo stage should be initialized and set somewhere near 
% the middle of the range of motion (or just not at the edges).

% Make sure this matches the value in AndorPreview!
cropsize = [20 20];

xPos = readX(mcl_handle);
yPos = readY(mcl_handle);

dx = 0.1; % um
dy = 0.1; % um
nSteps = 10;

xrange = xPos + [dx:dx:dx*nSteps];
yrange = yPos + [dy:dy:dy*nSteps];

[X Y] = meshgrid(xrange,yrange);

imagedata = cell(size(X));
stats = zeros(50,6,nSteps,nSteps);

[ret]=SetShutter(0, 1, 50, 50);                 %   Open the shutter

for k=1:5
    
    piezoX(1,X(1,1));
    piezoY(1,Y(1,1)); pause(1);
    
    % Step the stage, acquire 50 images per position, do the fitting
    for i=1:nSteps
        disp(i)
        for j=1:nSteps
            piezoX(1,X(i,j));
            piezoY(1,Y(i,j));
            pause(.25);
            imagedata{i,j} = return50Frames(cropsize(1),cropsize(2));    
            stats(:,:,i,j) = gsolve2d(reshape(imagedata{i,j},[prod(cropsize)*50,1]),cropsize);
        end
    end
        
    
    xm = squeeze(mean(stats(:,3,:,:),1));
    ym = squeeze(mean(stats(:,4,:,:),1));
    
    xAll = squeeze(stats(:,3,:,:));
    yAll = squeeze(stats(:,4,:,:));
    
    deltaXm = diff(mean(xm,2));
    deltaYm = diff(mean(ym,1));
    xmBar = mean(deltaXm);
    ymBar = mean(deltaYm);
    
    xMagnification(k) = abs(1000*dx/xmBar)
    yMagnification(k) = abs(1000*dy/ymBar)
end

    [ret]=SetShutter(0, 2, 50, 50);                 %   Close the shutter
