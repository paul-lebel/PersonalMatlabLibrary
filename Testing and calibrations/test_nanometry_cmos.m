% Test how well nanometry rejects physical motion of the stage.
% This script will move the piezo stage in a +/- 50 nm square wave, and
% acquire images at each position. The defocus z-signal as well as the
% nanometry z-signal will be calculated.


subcropsize = [20 20];
dt = 1/2000;

% create files to save the movies and data
% filename = input('Enter filename for movies (no .dat needed) ');

imagesPerZ = 100;
xsize = 128;
ysize = 32;
framesize = xsize*ysize;
imagedata = zeros(xsize,ysize,imagesPerZ);

zPos = readZ(1);
modMax = 500;
modVec = linspace(-modMax,modMax,21)/1000;
dMod = mean(diff(modVec));
z = zPos + modVec;
numRepeats = 10;

left = zeros([subcropsize(1), subcropsize(2), imagesPerZ*numel(z), numRepeats]);
right = left;

bg = takeBG(vid,100,'F:/',100,1);

% Preview and define crops
previewData = returnNCMOSFrames(vid,100,1,100);
[~, cropCoords(1,:)] = cropAndroll(previewData,subcropsize);
[~, cropCoords(2,:)] = cropAndroll(previewData,subcropsize); clear temp;

for j=1:numRepeats
    for i=1:numel(z)
        % Move the piezo to the ith position
        piezoZ(1,z(i)); pause(.25);
        
        % Frame index
        ind1 = (i-1)*imagesPerZ+1;
        ind2 = i*imagesPerZ;
        
        imagedata = returnNCMOSFrames(vid,imagesPerZ,1,100);
        imagedata = bsxfun(@minus,imagedata,bg);
        left(:,:,ind1:ind2,j) = imagedata(cropCoords(1,1):cropCoords(1,2)-1,cropCoords(1,3):cropCoords(1,4)-1,:);
        right(:,:,ind1:ind2,j) = imagedata(cropCoords(2,1):cropCoords(2,2)-1,cropCoords(2,3):cropCoords(2,4)-1,:);
        
        subplot(1,2,1);
        imagesc(left(:,:,ind2,j));
        subplot(1,2,2);
        imagesc(right(:,:,ind2,j));
        
    end
end

piezoZ(1,zPos);

stdLeft = zeros(numel(z),numRepeats);
stdRight = stdLeft;

for j=1:numRepeats
    for i=1:size(left,3)
        temp = squeeze(left(:,:,i,j));
        stdLeft(i,j) = std(temp(:));
        temp = squeeze(right(:,:,i,j));
        stdRight(i,j) = std(temp(:));
    end
end

stdMet = (stdLeft-stdRight)./(stdLeft+stdRight);
accumInds = 1+[floor([0:2099]/100)]';
stdMet_collapsed = accumarray(accumInds,mean(stdMet,2))./accumarray(accumInds,1);

pFit = polyfit(stdMet_collapsed,transpose(modVec)*1000,3);
zRaw = polyval(pFit,stdMet);
zMean = mean(zRaw,2);


% Reshape 'left' and 'right' into 3D arrays, temporarily for callStinky
dims = size(left);
left = reshape(left,[size(left,1) size(left,2),size(left,3)*size(left,4)]);
right = reshape(right,[size(right,1) size(right,2),size(right,3)*size(right,4)]);

% [cxl cyl sxl syl Il hl Offsetl] = CallStinkyPlus_WS(left);
% [cxr cyr sxr syr Ir hr Offsetr] = CallStinkyPlus_WS(right);

statsl = gsolve2d(left(:),[size(left,1) size(left,2)]);
statsr = gsolve2d(right(:),[size(right,1) size(right,2)]);

Il = statsl(:,2).*statsl(:,5).*statsl(:,6);
Ir = statsr(:,2).*statsr(:,5).*statsr(:,6);

zDecay = 147;
zLeftNano = zeros(imagesPerZ,numel(z),numRepeats);
zRightNano = zLeftNano;

for i=1:numRepeats
    for j = 1:numel(z)
        i1 = 1+ (j-1)*imagesPerZ + (i-1)*imagesPerZ*numel(z)
        i2 = j*imagesPerZ+ (i-1)*imagesPerZ*numel(z)
        zLeftNano(:,j,i) = subPoly(-zDecay*log(Il(i1:i2)),0);
        zRightNano(:,j,i) = subPoly(-zDecay*log(Ir(i1:i2)),0);
        pause(.3);
    end
end

zLeftNanoMean = mean(zLeftNano,3);
zRightNanoMean = mean(zRightNano,3);

zLeftMeanMean = mean(zLeftNanoMean,1)';
zRightMeanMean = mean(zRightNanoMean,1)';


zMean2 = zeros(numel(z),1);
% 
for i=1:numel(z)*imagesPerZ
    j = ceil(i/imagesPerZ);
%     zLeft2(j) = zLeft2(j) + zLeftNanoMean(i)/imagesPerZ;
%     zRight2(j) = zRight2(j) + zRightNanoMean(i)/imagesPerZ;
    zMean2(j) = zMean2(j) + zMean(i)/imagesPerZ;
end


time = dt:dt:numel(z)*imagesPerZ*dt;

figure;
plot(time,subPoly(zMean,0),'linewidth',2); hold all;
% set(gca,'Ytick',[-50 0 50]);
plot(time,zLeftNanoMean(:),'linewidth',2);
plot(time,zRightNanoMean(:),'linewidth',2);
legend('Defocus z-signal','Left path nanometry','Right path nanometry')
title('Response of axial measurements to a 50 nm modulation of the piezo stage','fontsize',14)
xlabel('Time (s)','fontsize',14);
ylabel('Z (nm) (nanometry uncalibrated!!!)','fontsize',14);
% set(gca,'Ytick',[-modMax:dMod:modMax]);
ylim([-(modMax+50) (modMax+50)]);
grid

figure;
plot(modVec*1000,subPoly(zMean2,0),'o-','linewidth',2); hold all;
plot(modVec*1000,zLeftMeanMean,'o-','linewidth',2); hold all;
plot(modVec*1000,zRightMeanMean,'o-','linewidth',2);