
zDecay = 120; % nm, from measurement
% xMag = 106.66; % nm/pixel
% yMag = 100.95; % nm/pixel
deltaTheta = .0178; % radians

% Process raw from Andor...
% % 
[left dir]  = getRawuiAuto([10 10]);
% % 
load([dir 'lockInfo.mat']);

% Load the laser and stage data and pFit
fid = fopen([dir '\ldata.txt'],'r');
header = fscanf(fid,'%s \n',[1 4]);
ldata = fscanf(fid,'%f %f %f %f \n');
Time = ldata(1:4:numel(ldata));
Sum = ldata(2:4:numel(ldata)); % Focus lock laser
Pos = ldata(3:4:numel(ldata));
Count = ldata(4:4:numel(ldata));
fclose(fid);


% Compute the PSD z signal
% PSD_to_nm = 4224; % Measured 2/9/2012
PSD_to_nm = 2127;
% darkSignalXsum = -49.560E-3; % Visible path
darkSignalXsum = .0008; % IR path
ynorm = -Pos./(Sum(1:numel(Pos))-darkSignalXsum);
zPSD = PSD_to_nm*ynorm;
zPSD = accumarray(1+Count,zPSD(1:numel(Count)));
weights = accumarray(1+Count,1);
zPSD = zPSD(2:end)./weights(2:end);

tic;
% Do fast 2D Gaussian fits on the image stack
[cx cy sx sy I h Offset] = CallStinkyPlus_WS(left);
toc

% Clip outliers; usually caused by another particle diffusing through the
% field of view
outlierTol = 3.5; % standard deviations

cx = min(cx, mean(cx)+outlierTol*std(cx));
cx = max(cx, mean(cx)-outlierTol*std(cx));

cy = min(cy, mean(cy)+outlierTol*std(cy));
cy = max(cy, mean(cy)-outlierTol*std(cy));


% Geometry needs flipping to map correctly to sample plane. Factor of 1.2
% is empirical for so far ONE rotor only. Fix this properly with
% magnification measurement!!!!
cx_dc = 105*subPoly(-cx,11)*1;
cy_dc = 105*subPoly(-cy,11)/1;

n = numel(cx_dc);

dt = Kinetic;
% dt = 1/lockInfo.camRate;
% dt = 6373.5;
fs = 1/dt;
time = dt:dt:dt*n;
 
% Fit circles every chunk of data and subtract centre (method 3)
chunksize = 10000; % [Frames]
numcorrs = floor(n/chunksize);
for i = 1:numcorrs
    chunk = (1+(i-1)*chunksize):(i*chunksize);
    [xtemp ytemp nothing] = circleFit_dc(cx_dc(chunk),cy_dc(chunk));
    cx_dc(chunk) = cx_dc(chunk) - xtemp;
    cy_dc(chunk) = cy_dc(chunk) - ytemp;
    disp(i/numcorrs);
end
chunk = (n-chunksize+1):n;
[xtemp ytemp nothing] = circleFit_dc(cx(chunk),cy(chunk));
cx_dc(chunk) = (cx_dc(chunk) - xtemp);
cy_dc(chunk) = (cy_dc(chunk) - ytemp);




[xo yo ro] = circleFit(cx_dc,cy_dc)

cx_dc = cx_dc-xo;
cy_dc = cy_dc-yo;

angle = unwrap(atan2(cy_dc,cx_dc));

densfig = figure;
relateC(cx_dc,cy_dc,100); axis equal
title('Position map in image plane   ','fontsize',12);
hold all;
fitdomain = linspace(-ro,ro,500);
plot(fitdomain,sqrt(ro^2-(fitdomain.^2)),'k','LineWidth',1); 
plot(fitdomain,-sqrt(ro^2-(fitdomain).^2),'k','LineWidth',1);
txtstr = ['D = ' num2str(2*ro) ' nm'];
xlabel(txtstr,'fontsize',12);
saveas(densfig,[dir 'densMap.fig']);

% 
laserSum = accumarray(Count+1,Sum(1:numel(Count)));
weights = accumarray(Count+1,1);

laserSum = laserSum(2:end)./weights(2:end);

% .0008 is the IR detector's dark signal
Itry = -I(1:min(length(I),length(laserSum)))./(laserSum(1:min(length(I),length(laserSum)))-darkSignalXsum); % 0.049 is a dark signal value measured Feb 2012

angleWrapped = atan2(cy_dc,cx_dc);
[awsorted IX] = sort(angleWrapped);
ITrysorted = Itry(IX);
FS_coeffs = Fcoeffs4(awsorted,ITrysorted);
FS_func = FS_gen(angleWrapped,FS_coeffs);
ItryFS = Itry./FS_func;
    
% ItryFS = -IcorrFS(1:min(length(IcorrFS),length(laserSum)))./(smooth(laserSum(1:min(length(IcorrFS),length(laserSum))),10)-darkSignalXsum); % 0.049 is a dark signal value measured Feb 2012

% 
[psd f] = pwelch(angle-mean(angle),[],[],[],lockInfo.camRate);
[a fo] = lorenzFit(f(10:end),psd(10:end));

% cosFig = figure;
% [cosOffset cosAmp phi] = Cos2_Fit(mod(angle(1:length(Itry)),2*pi),Itry);
% ICorr = Itry./(cosOffset + cosAmp*cos(mod(angle(1:length(Itry)),2*pi)+phi).^2);
% saveas(cosFig,[dir 'cos2Fit.fig']);

zEvNano = -zDecay*log(Itry);
zFSCorr = -zDecay*log(ItryFS);
% zEvCorr = -zDecay*log(ICorr);

% 
Imap = accumarray(round(300+ [cx_dc(1:numel(Itry)),cy_dc(1:numel(Itry))]),Itry);
ImapCorr = accumarray(round(300+[cx_dc(1:numel(ItryFS)),cy_dc(1:numel(ItryFS))]),ItryFS);
Iweights = accumarray(round(300+ [cx_dc(1:numel(ItryFS)),cy_dc(1:numel(ItryFS))]),1);
load('mapi64.mat');
ImapFig = figure; 
subplot(2,1,1);
imagesc(rot90(Imap./Iweights)); %,[min(Itry) max(Itry)]); colorbar;
colorbar;
subplot(2,1,2);
imagesc(FS_coeffs(1)*rot90(ImapCorr./Iweights),[min(Itry) max(Itry)]); 
colorbar;
colormap(mapi64);
saveas(ImapFig,[dir 'ImapCompare.fig']);

[psdz fz] = pwelch(subPoly(zEvNano,2),[],[],[],fs);
[psdzcorr fzcorr] = pwelch(subPoly(zFSCorr,2),[],[],[],fs);
[az foz] = lorenzFit(fz(10:end),psdz(10:end));
[azfs fozfs] = lorenzFit(fzcorr(10:end),psdzcorr(10:end));

% Fit the position distribution to extract mean angle,
% variance, center, etc.
% 
[params N P] = rotorFit(cx_dc,cy_dc);
load('mapi64.mat')
distFig = figure;
subplot(1,2,1); imagesc(flipud(N));
hold all
x = 50 + [1:60]*cos(params.t0);
y = 50 - [1:60]*sin(params.t0);
plot(x,y,'k')
axis equal; axis([0 100 0 100]); colormap(mapi64);
subplot(1,2,2); imagesc(flipud(P));
hold all
x = 50 + [1:60]*cos(params.t0);
y = 50 - [1:60]*sin(params.t0);
plot(x,y,'k')
axis equal; axis([0 100 0 100]); colormap(mapi64);
saveas(distFig,[dir 'distNCompare.fig']);
params
clear left right
save([dir 'analysis.mat']);
