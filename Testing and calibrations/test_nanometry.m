% Test how well nanometry rejects physical motion of the stage.
% This script will move the piezo stage in a +/- 50 nm square wave, and
% acquire images at each position. The defocus z-signal as well as the
% nanometry z-signal will be calculated. 

if ~exist('cropVec')
    cropVec = [1,512,1,512];
end

s.stop;

subcropsize = [20 20];

% create files to save the movies and data
% filename = input('Enter filename for movies (no .dat needed) ');

ret = SetImage(1,1,cropVec(1),cropVec(2),cropVec(3),cropVec(4));
imagesPerZ = 100;
xsize = cropVec(2)-cropVec(1) + 1;
ysize = cropVec(4)-cropVec(3) + 1;
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

[ret]=SetShutter(0, 1, 50, 50);                 %   Open the shutter

% Preview and define crops
previewData = return100Frames(xsize,ysize);
[temp cropCoords(1,:)] = cropAndroll(previewData,subcropsize);
[temp cropCoords(2,:)] = cropAndroll(previewData,subcropsize); clear temp;

for j=1:numRepeats
for i=1:numel(z)
    % Move the piezo to the ith position
    piezoZ(1,z(i)); pause(.25);
    
    % Frame index
    ind1 = (i-1)*imagesPerZ+1;
    ind2 = i*imagesPerZ;
    
    imagedata = returnNFrames(xsize,ysize,imagesPerZ);
    left(:,:,ind1:ind2,j) = imagedata(cropCoords(1,1):cropCoords(1,2)-1,cropCoords(1,3):cropCoords(1,4)-1,:);
    right(:,:,ind1:ind2,j) = imagedata(cropCoords(2,1):cropCoords(2,2)-1,cropCoords(2,3):cropCoords(2,4)-1,:);
    
    subplot(1,2,1);
    imagesc(left(:,:,ind2,j));
    subplot(1,2,2);
    imagesc(right(:,:,ind2,j));
    
end
end

[ret]=SetShutter(0, 2, 50, 50);                 %   Close the shutter


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

[cxl cyl sxl syl Il hl Offsetl] = CallStinkyPlus_WS(left);
[cxr cyr sxr syr Ir hr Offsetr] = CallStinkyPlus_WS(right);

Il = reshape(Il,dims(3:4));
Ir = reshape(Ir,dims(3:4));

zDecay = 147;

for i=1:numRepeats
zLeftNano(:,i) = subPoly(-zDecay*log(Il(:,i)),0);
zRightNano(:,i) = subPoly(-zDecay*log(Ir(:,i)),0);
end

zLeftNanoMean = mean(zLeftNano,2);
zRightNanoMean = mean(zRightNano,2);

zLeft2 = zeros(numel(z),1);
zRight2 = zLeft2;
zDefoc2 = zLeft2;
zMean2 = zLeft2;

for i=1:numel(zLeftNanoMean)
    j = ceil(i/imagesPerZ);
    zLeft2(j) = zLeft2(j) + zLeftNanoMean(i)/imagesPerZ;
    zRight2(j) = zRight2(j) + zRightNanoMean(i)/imagesPerZ;
    zMean2(j) = zMean2(j) + zMean(i)/imagesPerZ;
end


time = Kinetic:Kinetic:numel(z)*imagesPerZ*Kinetic;

figure;
plot(time,subPoly(zMean,0),'linewidth',2); hold all;
% set(gca,'Ytick',[-50 0 50]);
plot(time,zLeftNanoMean,'linewidth',2);
plot(time,zRightNanoMean,'linewidth',2);
legend('Defocus z-signal','Left path nanometry','Right path nanometry')
title('Response of axial measurements to a 50 nm modulation of the piezo stage','fontsize',14)
xlabel('Time (s)','fontsize',14);
ylabel('Z (nm) (nanometry uncalibrated!!!)','fontsize',14);
% set(gca,'Ytick',[-modMax:dMod:modMax]);
ylim([-(modMax+50) (modMax+50)]);
grid

figure; 
plot(modVec*1000,subPoly(zMean2,0),'o-','linewidth',2); hold all;
plot(modVec*1000,zLeft2,'o-','linewidth',2); hold all;
plot(modVec*1000,zRight2,'o-','linewidth',2);