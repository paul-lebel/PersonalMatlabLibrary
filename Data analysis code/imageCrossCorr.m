
function [xPeak_um, yPeak_um, alignedCroppedImages] = imageCrossCorr(varargin)

% Performs a normalized 2D cross-correlation on an image stack vs. a
% template. The template can either be specifically selected by the user or
% it can be read in as the first image of the stack. Optional cropping of
% both template and/or image stack is also included as an interactive
% option.

% Additionally, sub-pixel sampling is optionally included as an interactive
% option. This feature uses a surrounding window in the normxcorr2 array
% and fits the peak to a 2D Gaussian function to resolve image shifts that
% are below 1 pixel.

% Output args are the located best fit offsets (in microns) between the
% template and each image in the stack. 

% Paul Lebel
% Berkeley Lights Inc.
% 1/30/2017

% If providing arguments:
% imageCrossCorr(template, stack, pixelSize_um)

% Otherwise, you will be querried for the answers

nargin = numel(varargin);

if nargin < 2 % No template and stack provided provided
pathname = uigetdir();
dir1 = pwd;
cd(pathname);
baselist = dir;
count = 0;
nFiles = numel(baselist);

templateChoice = questdlg('Would you like to choose a template (first image is used otherwise)?', '', 'Yes', 'No Thank You','No Thank You');

switch templateChoice
    case 'Yes'
        [tempFilename, tempPathname] = uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';...
          '*.*','All Files' },'Select a template image');
        template = imread([tempPathname '\' tempFilename]);
  
    case 'No Thank You'
        % Read in first image to display to user
        for i=1:nFiles
            if strfind(baselist(i).name, '.tif') % There is a '.tif' or 'tiff' image in the folder
                template = imread(baselist(i).name);
                break;
            end
        end
end

tempFig = figure;
imagesc(template);
cropChoice = questdlg('Would you like to crop the template?', '', 'Yes', 'No Thank You','No Thank You');
delete(tempFig);

% Handle response
switch cropChoice
    case 'Yes'
        [template, ~] = cropMovie(template);
    otherwise
end
    
% Read in first image, which needs to be done either way
for i=1:nFiles
    if strfind(baselist(i).name, '.tif') % There is a '.tif' or 'tiff' image in the folder
        image1 = imread(baselist(i).name);
        break;
    end
end

cropChoice = questdlg('Would you like to crop the stack?', '', 'Yes', 'No Thank You','No Thank You');
switch cropChoice
    case 'Yes'
         
        [image1, cropCoordVec] = cropMovie(image1);
        stack = zeros([size(image1), nFiles], 'uint16');
        h= waitbar(0,'Reading images...');
        % Read in all the images in the base folder
        for j=1:nFiles
            %numel(baselist)
            if strfind(baselist(j).name, '.tif') % There is a '.tif' or 'tiff' image in the folder
                count = count+1;
                tempFrame = imread(baselist(j).name);
                stack(:,:,count) = tempFrame(cropCoordVec(1):cropCoordVec(2), cropCoordVec(3):cropCoordVec(4));
            end
            waitbar(j/nFiles);
        end
        
    case 'No Thank You'
        delete(tempFig);
        stack = zeros([size(image1), nFiles], 'uint16');
        h= waitbar(0,'Reading images...');
        % Read in all the images in the base folder
        for j=3:nFiles
            %numel(baselist)
            if strfind(baselist(j).name, '.tif') % There is a '.tif' or 'tiff' image in the folder
                count = count+1;
                stack(:,:,count) = imread(baselist(j).name);
            end
            waitbar(j/nFiles);
        end
end

nImages = count;
stack = stack(:,:,1:nImages);
delete(h);
pixelSize_um = inputdlg('Please enter the image pixel size (um)') ;
pixelSize_um = str2double(pixelSize_um{1});

else
    template = varargin{1};
    stack = varargin{2};
    pathname = pwd;
    baselist = {''};
    dir1 = pwd;
    pixelSize_um = varargin{3};
end



dims = size(stack);
if numel(dims) < 3
    dims(:,:,1) = 1;
end

h= waitbar(0,'Performing normalized 2D cross-correlation...');

% Loop through all the images and compute normxcorr2
for i=1:dims(3)
    c(:,:,i) = normxcorr2(template, stack(:,:,i));
    waitbar(i/dims(3));
end
delete(h);

xPeak = zeros(dims(3),1);
yPeak = xPeak;
for i=1:dims(3)
    c1 = c(:,:,i);
    [yPeak(i), xPeak(i)] = find(c1==max(c1(:)),1);
end

xOffset_pixels = xPeak - ceil(size(c,2)/2);
yOffset_pixels = yPeak - ceil(size(c,1)/2);

sampChoice = questdlg('Perform sub-pixel sampling?', '', 'Yes', 'No Thank You','No Thank You');

switch sampChoice
    case 'Yes'
        kernalSize = 3; % Always make this an odd number!
        cCropped = zeros(2*kernalSize+1, 2*kernalSize+1, dims(3));
        for i=1:dims(3)
            cCropped(:,:,i) = c((yPeak(i) - kernalSize):(yPeak(i)+kernalSize), (xPeak(i)-kernalSize):(xPeak(i)+kernalSize),i);
        end
%         [xFine, yFine, ~,~] = com_calc(cCropped);
        params = gsolve2d(cCropped(:),[size(cCropped,1), size(cCropped,2)]);
        xFine = params(:,4)-kernalSize;
        yFine = params(:,3)-kernalSize;
        
    case 'No Thank You'
        xFine = zeros(dims(3),1);
        yFine = xFine;
end

alignedCroppedImages = zeros(size(template));
centerCropIndsY = floor(size(stack,1)/2 - size(template,1)/2):floor(size(stack,1)/2 - size(template,1)/2 + size(template,1)-1);
centerCropIndsX = floor(size(stack,2)/2 - size(template,2)/2):floor(size(stack,2)/2 - size(template,2)/2 + size(template,2)-1);

% for i=1:dims(3)
%     indsY = centerCropIndsY + yOffset_pixels(i);
%     indsX = centerCropIndsX + xOffset_pixels(i);
%     alignedCroppedImages(:,:,i) = stack(indsY, indsX, i);
% end
for i=1:dims(3)
    indsY(:,i) = centerCropIndsY + yOffset_pixels(i);
    indsX(:,i) = centerCropIndsX + xOffset_pixels(i);
end
indsY = max(1,indsY);
indsY = min(dims(1),indsY);
indsX = max(1,indsX);
indsX = min(dims(2),indsX);
for i=1:dims(3)
    alignedCroppedImages(:,:,i) = stack(indsY(:,i), indsX(:,i), i);
end

xPeak_um = pixelSize_um*(xPeak+xFine);
yPeak_um = pixelSize_um*(yPeak+yFine);
goodInds = isfinite(xPeak_um) & isfinite(yPeak_um);
xPeak_um = xPeak_um(goodInds);
yPeak_um = yPeak_um(goodInds);
xPeak_um = subPoly(xPeak_um,0);
yPeak_um = subPoly(yPeak_um,0);

yPeakValley_um = max(yPeak_um(:)) - min(yPeak_um(:));
xPeakValley_um = max(xPeak_um(:)) - min(xPeak_um(:));

figure;
plot(xPeak_um); hold all;
plot(yPeak_um);
xlabel('Stack frame number','fontsize',16);
ylabel('Detected Image Shift (\mum)','fontsize',16);
title(['2D cross-correlation: PV-x = ' num2str(xPeakValley_um) ' , PV-y = ' num2str(yPeakValley_um)],'fontsize',18);
legend('X','Y');

figure;
plot(xPeak_um, yPeak_um,'o','linewidth',2);
xlabel('Detected Image Shift (X, \mum)','fontsize',16);
ylabel('Detected Image Shift (Y, \mum)','fontsize',16);
grid; axis equal;
save([pathname '\Normxcorr2data.mat'], 'xPeak_um', 'yPeak_um', 'xPeakValley_um','yPeakValley_um','baselist','pixelSize_um');

cd(dir1);
