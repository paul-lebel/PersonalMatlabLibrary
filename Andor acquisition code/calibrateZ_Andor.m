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

clear leftSmear rightSmear psdzRight psdzLeft psdzDefoc

if ~exist('cropVec')
    cropVec = [1,512,1,512];
end

s.stop;

subcropsize = [22 22];

% Define parameters
totalFrames = 20000;
scanForce = 1;
% smearForce= [0.5 1 2 10];
smearForce = [.5];

% Allocate variables
zDefoc = zeros(totalFrames,numel(smearForce));
Il = zDefoc; Ir = Il; cxl = Il; cyl = Il; sxl = Il;
syl = Il; hl = Il; hr = Il; Offsetl = Il; cxr = Il;
cyr = Il; sxr = Il; syr = Il; Offsetr = Il;
stdMetSmear = Il; stats.cxl = cxl; stats.cyl = cyl; stats.sxl = sxl;
stats.syl = syl; stats.Il = Il; stats.hl = hl; stats.Offsetl = Offsetl;
stats.cxr = cxr; stats.cyr = cyr; stats.sxr = sxr; stats.syr = syr;
stats.Ir = Ir; stats.hr = hr; stats.Offsetr = Offsetr;
IlSmear = Il; IrSmear = Il; meanISmear = Il; zRight = Il;
zLeft = Il; defocSmear = Il;
ItryFSl = Il; ItryFSr = Il;
zRight2 = Il; zLeft2 = Il;

clear psdzRight psdzLeft psdzDefoc psdzLeft2 psdzRight2

setForce(magnetHeight_obj,scanForce);


% create files to save the movies and data
% filename = input('Enter filename for movies (no .dat needed) ');
filename = 'allData.mat';
% start_path = 'F:\Paul_Data\2013\October 2013';
start_path = 'F:\Paul_Data\2013\November 2013\Nov 12th_Channels7th\CH2_SGS420_140nm\Mol1 phys buff monomer';
dirname = uigetdir(start_path,'Select directory to save');
[~, ~, ~, hour, min, sec] = datevec(now);
subdirname = strcat(dirname,'\',num2str(hour),'_',num2str(min));
clear min;
mkdir(subdirname);
pathname = strcat(subdirname, '\' ,filename);

ret = SetImage(1,1,cropVec(1),cropVec(2),cropVec(3),cropVec(4));
imagesPerZ = 50;
xsize = cropVec(2)-cropVec(1) + 1;
ysize = cropVec(4)-cropVec(3) + 1;
framesize = xsize*ysize;
imagedata = zeros(xsize,ysize,imagesPerZ);

zPos = readZ(1);
z = zPos + [-.5: .02 : .5];

left = zeros([subcropsize(1) subcropsize(2) imagesPerZ*numel(z)]);
right = left;

[ret]=SetShutter(0, 1, 50, 50);                 %   Open the shutter

% Preview and define crops
previewData = return100Frames(xsize,ysize);
[temp cropCoords(1,:)] = cropAndroll(previewData,subcropsize);
[temp cropCoords(2,:)] = cropAndroll(previewData,subcropsize); clear temp;


for i=1:numel(z)
    % Move the piezo to the ith position
    piezoZ(1,z(i)); pause(.1);
    
    % Frame index
    ind1 = (i-1)*imagesPerZ+1;
    ind2 = i*imagesPerZ;
    
    imagedata = return50Frames(xsize,ysize);
    left(:,:,ind1:ind2) = imagedata(cropCoords(1,1):cropCoords(1,2)-1,cropCoords(1,3):cropCoords(1,4)-1,:);
    right(:,:,ind1:ind2) = imagedata(cropCoords(2,1):cropCoords(2,2)-1,cropCoords(2,3):cropCoords(2,4)-1,:);
    
    subplot(1,2,1);
    imagesc(left(:,:,ind2));
    subplot(1,2,2);
    imagesc(right(:,:,ind2));
    
end

piezoZ(1,zPos);
setupLockOnly;
setForce(magnetHeight_obj,smearForce(1));

stdLeft = zeros(size(left,3),1);
stdRight = stdLeft;
for i=1:size(left,3)
    temp = left(:,:,i);
    stdLeft(i) = std(temp(:));
    temp = right(:,:,i);
    stdRight(i) = std(temp(:));
end
stdMet = (stdLeft-stdRight)./(stdLeft+stdRight);

stdSynch = zeros(numel(z),1);
% ImetSynch = stdSynch;
for i=1:numel(stdMet)
    j = ceil(i/imagesPerZ);
    stdSynch(j) = stdSynch(j)+stdMet(i);
    %     ImetSynch(j) = ImetSynch(j) + Imet(i);
end
stdSynch = stdSynch/imagesPerZ;
% ImetSynch = ImetSynch/10;

figure;
plot(stdSynch,z); axis tight;


ub = input('Enter upper bound for z  ');
lb = input('Enter lower bound for z  ');
z2inds = find(z > lb & z < ub);
z2 = z(z2inds)';
stdSynch2 = stdSynch(z2inds);

% Plot defocus calibration curve
defocusScan = figure;
pFit = polyfit(stdSynch2,z2,3);
plot(stdSynch2,polyval(pFit,stdSynch2)','b-','linewidth',2);
hold all;
plot(stdSynch2,z2,'ro');


disp('Taking smear vid');
pause(5); % Let focus lock equilibriate

% setupLockWithAndor; pause(3); disp('Taking long vid');
% s.stop;

% imagedata = returnNFrames(xsize,ysize,50000); disp('Done taking smear vid');

% Trying this new strategy: slow scan the magnets over the course of the
% whole movie, ramping the force up.
% totalMovieTime = totalFrames*Kinetic;
% magnetVel = abs(Ftoh_halfInch([scanForce - smearForce])/totalMovieTime);
% magnetHeight_obj.VEL('1',magnetVel);
% setForce(magnetHeight_obj, scanForce);


for k=1:numel(smearForce)
    
    setForce(magnetHeight_obj,smearForce(k)); pause(5);
    
    imagedata = returnNFrames(xsize,ysize,totalFrames); disp('Done taking smear vid');
    
    leftSmear{k} = imagedata(cropCoords(1,1):cropCoords(1,2)-1,cropCoords(1,3):cropCoords(1,4)-1,:);
    rightSmear{k} = imagedata(cropCoords(2,1):cropCoords(2,2)-1,cropCoords(2,3):cropCoords(2,4)-1,:);
    
    stdLeftSmear = zeros(totalFrames,1);
    stdRightSmear = stdLeftSmear;
    
    for i=1:size(leftSmear{k},3)
        temp = leftSmear{k}(:,:,i);
        stdLeftSmear(i) = std(temp(:));
        temp = rightSmear{k}(:,:,i);
        stdRightSmear(i) = std(temp(:));
    end
    
    stdMetSmear(:,k) = (stdLeftSmear-stdRightSmear)./(stdLeftSmear+stdRightSmear);
    
    % zDefoc = (1.33/1.515)*1000*subPoly(polyval(pFit,stdMetSmear),0);
    zDefoc(:,k) = 0.84*1000*subPoly(polyval(pFit,stdMetSmear(:,k)),0); % 0.84 is the value measured by Aakash for [Lebel et al. 2013]
    zDefoc(:,k) =  min(zDefoc(:,k), mean(zDefoc(:,k)) + 5*std(zDefoc(:,k)));
    zDefoc(:,k) =  max(zDefoc(:,k), mean(zDefoc(:,k)) - 5*std(zDefoc(:,k)));
end

s.stop;
setForce(magnetHeight_obj,.5);
[ret]=SetShutter(0, 2, 50, 50);                 %   Close the shutter

%%

for k=1:numel(smearForce)
    [cxl cyl sxl syl Il hl Offsetl] = CallStinkyPlus_WS(leftSmear{k});
    [cxr cyr sxr syr Ir hr Offsetr] = CallStinkyPlus_WS(rightSmear{k});
    
    % Remove outliers
    cxl = min(cxl, mean(cxl) + 4*std(cxl));
    cxl = max(cxl, mean(cxl) - 4*std(cxl));
    cyl = min(cyl, mean(cyl) + 4*std(cyl));
    cyl = max(cyl, mean(cyl) - 4*std(cyl));
    Il =  min(Il, mean(Il) + 5*std(Il));
    Il =  max(Il, mean(Il) - 5*std(Il));
    Ir =  min(Ir, mean(Ir) + 5*std(Ir));
    Ir =  max(Ir, mean(Ir) - 5*std(Ir));
    
    [cxl cyl rol] = driftCorrect(cxl,cyl,Kinetic);
    [cxr cyr ror] = driftCorrect(cxr,cyr,Kinetic);
    
    stats.cxl(:,k) = cxl;
    stats.cyl(:,k) = cyl;
    stats.sxl(:,k) = sxl;
    stats.syl(:,k) = syl;
    stats.Il(:,k) = Il;
    stats.hl(:,k) = hl;
    stats.Offsetl(:,k) = Offsetl;
    stats.cxr(:,k) = cxr;
    stats.cyr(:,k) = cyr;
    stats.sxr(:,k) = sxr;
    stats.syr(:,k) = syr;
    stats.Ir(:,k) = Ir;
    stats.hr(:,k) = hr;
    stats.Offsetr(:,k) = Offsetr;
    
    
    %     Perform 4th order Fourier series correction to the intensity data
    
    angleWrappedl = atan2(cyl,cxl);
    [awsortedl IX] = sort(angleWrappedl);
    ITrysortedl = Il(IX);
    FS_coeffsl = Fcoeffs4(awsortedl,ITrysortedl);
    FS_funcl = FS_gen(angleWrappedl,FS_coeffsl);
    ItryFSl(:,k)= Il./FS_funcl;
    
    % And for the right
    angleWrappedr = atan2(cyr,cxr);
    [awsortedr IX] = sort(angleWrappedr);
    ITrysortedr = Ir(IX);
    FS_coeffsr = Fcoeffs4(awsortedr,ITrysortedr);
    FS_funcr = FS_gen(angleWrappedr,FS_coeffsr);
    ItryFSr(:,k)= Ir./FS_funcr;
    
    
    smoothFactor = 3;
    
%         IlSmear(:,k) = subPoly(smooth(-log(stats.Il(:,k)),smoothFactor),10);
%         IrSmear(:,k) = subPoly(smooth(-log(stats.Ir(:,k)),smoothFactor),10);
    IlSmear(:,k) = subPoly(smooth(-log(ItryFSl(:,k)),smoothFactor),21);
    IrSmear(:,k) = subPoly(smooth(-log(ItryFSr(:,k)),smoothFactor),21);
    meanISmear(:,k) = subPoly(smooth(-log((ItryFSl(:,k) + ItryFSr(:,k))/2),smoothFactor),21);
    defocSmear(:,k) = subPoly(smooth(zDefoc(:,k),smoothFactor),21);
    
    slopeFit(:,k) = polyfit(IrSmear(:,k),defocSmear(:,k),1);
    slopeFitl(:,k) = polyfit(IlSmear(:,k),defocSmear(:,k),1);
    slopeFitMean(:,k) = polyfit(meanISmear(:,k),defocSmear(:,k),1);
    
    Lambda(k) = slopeFit(1,k);
    Lambdal(k) = slopeFitl(1,k);
    LambdaMean(k) = slopeFitMean(1,k);
    
    if k==1
        smearFig(k) = figure;
        relateC(IrSmear(:,k),defocSmear(:,k),50);
        hold all;
        plot(IrSmear(:,k),polyval(slopeFit(:,k),IrSmear(:,k)),'k','linewidth',1);
        title(['\Lambda = ' num2str(Lambda(k)) ' nm'],'fontsize',12)
        xlabel('-log(Intensity)','fontsize',14);
        ylabel('\Delta z by DIO (nm)','fontsize',14);
        
        smearFigl(k) = figure;
        relateC(IlSmear(:,k),defocSmear(:,k),50);
        hold all;
        plot(IlSmear(:,k),polyval(slopeFitl(:,k),IlSmear(:,k)),'k','linewidth',1);
        title(['\Lambda = ' num2str(Lambdal(k)) ' nm'],'fontsize',12);
        xlabel('-log(Intensity)','fontsize',14);
        ylabel('\Delta z by DIO (nm)','fontsize',14);
        
        smearfigMean(k) = figure;
        relateC(meanISmear(:,k),defocSmear(:,k),50);
        hold all;
        plot(meanISmear(:,k),polyval(slopeFitMean(:,k),meanISmear(:,k)),'k','linewidth',1);
        title(['\Lambda = ' num2str(LambdaMean(k)) ' nm'],'fontsize',12);
        xlabel('-log(Intensity)','fontsize',14);
        ylabel('\Delta z by DIO (nm)','fontsize',14);
        
    end
%     zDecay = 140;
    zDecay = LambdaMean(1);
%     zDecay = mean([136 130 156 146 141 140 150 127]);
    
    zRight(:,k) = subPoly(-zDecay*log(stats.Il(:,k)),0);
    zLeft(:,k) = subPoly(-zDecay*log(stats.Ir(:,k)),0);
    zRight2(:,k) = subPoly(-zDecay*log(ItryFSr(:,k)),0);
    zLeft2(:,k) = subPoly(-zDecay*log(ItryFSl(:,k)),0);
    [psdzRight(:,k) fz]= pwelch(subPoly(zRight(:,k),1),[],[],[],1/Kinetic);
    [psdzDefoc(:,k) fz]= pwelch(subPoly(zDefoc(:,k),1),[],[],[],1/Kinetic);
    [psdzLeft(:,k) fz]= pwelch(subPoly(zLeft(:,k),1),[],[],[],1/Kinetic);
    [psdzLeft2(:,k) fz]= pwelch(subPoly(zLeft2(:,k),1),[],[],[],1/Kinetic);
    [psdzRight2(:,k) fz]= pwelch(subPoly(zRight2(:,k),1),[],[],[],1/Kinetic);
    
end
%%
clear imagedata;

keepthis = input('Keep the current calibration?','s');

if keepthis == 'y'
    save(pathname);
    saveas(smearFig(1),[subdirname '\smearFig.fig']);
    saveas(smearFigl(1),[subdirname '\smearFigl.fig']);
    saveas(smearfigMean(1),[subdirname '\smearFigMean.fig']);
    
    saveas(defocusScan(1),[subdirname '\defocusScan.fig']);
else
    rmdir(subdirname,'s');
end

figure;
for i=1:size(psdzDefoc,2)
loglog(fz,smooth(psdzDefoc(:,i),10)); hold all;
loglog(fz,smooth(psdzRight2(:,i),10));
end



