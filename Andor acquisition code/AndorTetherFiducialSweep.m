% Generate a defocus-based z calibration by imaging a stuck particle on the
% andor camera while stepping the height of the stage. Dual image crops are
% acquired, and results averaged for each z position of the piezo.

% Paul Lebel
% July 1st, 2012

% Assumptions:
% - piezo stage is initialized
% - Focus is adjusted so that the piezo can step upwards 0-2um and cover
% the desired defocus range
% - Andor is set up with the correct crop region (cropVec defined)

nPasses = 3;
cropsize =  [140 500];
% subcropsize = [];
% cropsize = [150 260];
subcropsize = [60 60];

magnetHeight_obj.MOV('1',24.5)
[ret]=SetAcquisitionMode(5);                    %   Set acquisition mode; 1 for Single Scan, 3 for kinetic, 5 for run till abort
[ret] = SetFrameTransferMode(1);
[ret] = SetIsolatedCropMode(1,cropsize(1),cropsize(2),1,1);
[ret]=SetExposureTime(0.000001);

xsize = cropsize(1);
ysize = cropsize(2);

% % Halt focus lock if it was running
% if exist(s)
%     s.stop;
% end


% create files to save the movies and data
% filename = input('Enter filename for movies (no .dat needed) ');
filename = 'stuckScan.mat';
start_path = 'F:\Paul_Data\2014\April';
dirname = uigetdir(start_path,'Select directory to save');
[~, ~, ~, hour, min, sec] = datevec(now);
subdirname = strcat(dirname,'\',num2str(hour),'_',num2str(min));
mkdir(subdirname);
% pathname = strcat(subdirname, '\' ,filename);

imagesPerZ = 10;

framesize = xsize*ysize;
imagedata = zeros(ysize,xsize,imagesPerZ);

zPos = readZ(1);
z = zPos + [-5: .02 : 3];

left = zeros([subcropsize(2) subcropsize(1) imagesPerZ*numel(z)]);
right = left;

[ret]=SetShutter(0, 1, 50, 50);                 %   Open the shutter

% Preview and define crops
previewData = return100Frames(ysize,xsize);
[temp cropCoords(1,:)] = cropAndroll(previewData,subcropsize);
[temp cropCoords(2,:)] = cropAndroll(previewData,subcropsize); clear temp;

[ret]=SetShutter(0, 1, 50, 50);                 %   Open the shutter


for g = 1:nPasses
disp(g)
for i=1:numel(z)
    disp(i/numel(z));
    % Move the piezo to the ith position
    piezoZ(1,z(i)); pause(.02);
    
    % Frame index
    ind1 = (i-1)*imagesPerZ+1;
    ind2 = i*imagesPerZ;
    
    imagedata = return10Frames(ysize,xsize);
    left(:,:,ind1:ind2) = imagedata(cropCoords(1,1):cropCoords(1,2)-1,cropCoords(1,3):cropCoords(1,4)-1,:);
    right(:,:,ind1:ind2) = imagedata(cropCoords(2,1):cropCoords(2,2)-1,cropCoords(2,3):cropCoords(2,4)-1,:);
    
    subplot(1,2,1);
    imagesc(left(:,:,ind2)); axis image;
    subplot(1,2,2);
    imagesc(right(:,:,ind2)); axis image;
    
end

piezoZ(1,zPos);

disp('Saving movies...')
save([subdirname '\left' num2str(g) '.mat'],'left');
save([subdirname '\right' num2str(g) '.mat'],'right');

end

[ret]=SetShutter(0, 2, 50, 50);                 %   Close the shutter
magnetHeight_obj.MOV('1',18)

save([subdirname '\' filename '_info.mat'],'ysize', 'zPos', 'z', 'xsize', 'start_path' ...
,'imagesPerZ', 'cropsize', 'cropCoords', 'Kinetic', 'Exposure', 'Accumulate');



% stdSynch = zeros(numel(z),1); 
% for i=1:numel(stdMet)
%     j = ceil(i/imagesPerZ);
%     stdSynch(j) = stdSynch(j)+stdMet(i);
% end
% stdSynch = stdSynch/imagesPerZ;
% 



% 
% % Grab data for smear plot
% % piezoZ(1,mean(z2)); 
% setupLockOnly; pause(5); disp('Taking smear vid');
% imagedata = returnNFrames(xsize,ysize,20000); disp('Done smear vid');
% 
% [ret]=SetShutter(0, 2, 50, 50);                 %   Close the shutter
% s.stop;
% 
% leftSmear = imagedata(cropCoords(1,1):cropCoords(1,2)-1,cropCoords(1,3):cropCoords(1,4)-1,:);
% rightSmear = imagedata(cropCoords(2,1):cropCoords(2,2)-1,cropCoords(2,3):cropCoords(2,4)-1,:);
% 
% stdLeftSmear = zeros(size(left,3),1);
% stdRightSmear = stdLeftSmear;
% 
% for i=1:size(leftSmear,3)
%     temp = leftSmear(:,:,i);
%     stdLeftSmear(i) = std(temp(:));
%     temp = rightSmear(:,:,i);
%     stdRightSmear(i) = std(temp(:));
% end
% 
% stdMetSmear = (stdLeftSmear-stdRightSmear)./(stdLeftSmear+stdRightSmear);





