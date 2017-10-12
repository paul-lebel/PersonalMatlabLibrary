

% This function accepts a batch of Gaussian fit parameters as input, and
% performs drift correction (by circle/ellipse fitting), angle computation,
% 4th order Fourier series correction of the nanometry z signal.

function statspp = batchPostProcessNoPSD(stats,dt)

% zDecay = 140; % nm, 
zDecay = 180;
% deltaTheta = .0178; % radians to rotate the data due to the tilting of the optosplit image
% 

% psdFlag = input('PSD and stage data?(1/0)');
psdFlag = 0;

if psdFlag
% Load the laser and stage data and pFit
fid = fopen([dir '\ldata.txt'],'r');
laserHeader = fscanf(fid,'%s \n',[1 4]);
ldata = fscanf(fid,'%f %f %f %f \n');
Time = ldata(1:4:numel(ldata));
Sum = ldata(2:4:numel(ldata)); % Focus lock laser
Pos = ldata(3:4:numel(ldata));
Count = ldata(4:4:numel(ldata));
fclose(fid);

fid = fopen([dir '\stageData.txt'],'r');
stageHeader = fscanf(fid,'%s \n',[1 3]);
stageData = fscanf(fid,'%f %f %f \n');
stagePos = stageData(1:3:numel(stageData));
delta = stageData(2:3:numel(stageData));
psdError = stageData(3:3:numel(stageData));
fclose(fid);
end

% Calibrated Sept.5th 2012
% xMag = 106.5;
% yMag = 103.13;

xMag = 93;
yMag = 93;

nMovies = size(stats.cx,2);
nFrames = size(stats.cx,1);
angle = zeros(size(stats.cx));
zFSCorr = zeros(size(stats.cx));
zEvNano = zFSCorr;
cx_dc = zFSCorr;
cy_dc = zFSCorr;
ItryFS = zFSCorr;
FS_func = zFSCorr;

kbT = 293.15*1.3806488E-23;
pN = 1E-12; nm = 1E-9;

fs = 1/dt;
time = [dt:dt:dt*nFrames];

for m = 1:nMovies
    
    disp(m);
    
    % Clip outliers; usually caused by another particle diffusing through the
    % field of view occasionally
    outlierTol = 3; % standard deviations
    stats.cx(:,m) = min(stats.cx(:,m), mean(stats.cx(:,m))+outlierTol*std(stats.cx(:,m)));
    stats.cx(:,m) = max(stats.cx(:,m), mean(stats.cx(:,m))-outlierTol*std(stats.cx(:,m)));
    stats.cy(:,m) = min(stats.cy(:,m), mean(stats.cy(:,m))+outlierTol*std(stats.cy(:,m)));
    stats.cy(:,m) = max(stats.cy(:,m), mean(stats.cy(:,m))-outlierTol*std(stats.cy(:,m)));
    
    % Geometry needs flipping to map correctly to sample plane.
    cx_dc(:,m) = xMag*subPoly(-stats.cx(:,m),5);
    cy_dc(:,m) = yMag*subPoly(-stats.cy(:,m),5);
    
    [cx_dc(:,m) cy_dc(:,m) ro(m)] = driftCorrect(cx_dc(:,m),cy_dc(:,m),dt);
   
    eStruct(m) = fit_ellipse(cx_dc(:,m),cy_dc(:,m));
    [xc(:,m) yc(:,m)] = fixEllipticity(cx_dc(:,m),cy_dc(:,m),eStruct(m));
    
    % Compute angle and its power spectrum
    angle(:,m) = unwrap(atan2(yc(:,m),xc(:,m)));
%     angle(:,m) = fixCrossings(angle(:,m),fs);
    [psd{m} f{m}] = pwelch(angle(:,m)-mean(angle(:,m)),[],[],[],fs);
    [a(m) fo(m)] = lorenzFit(f{m}(5:end),psd{m}(5:end));
    
    % Perform 4th order Fourier series correction to the intensity data
    angleWrapped = atan2(yc(:,m),xc(:,m));
    [awsorted IX] = sort(angleWrapped);
    ITrysorted = stats.I(IX,m);
    FS_coeffs(:,m) = Fcoeffs4(awsorted,ITrysorted);
    FS_func(:,m) = FS_gen(angleWrapped,FS_coeffs(:,m));
%     figure; plot(angleWrapped,smooth(ITrysorted,100),'.'); hold all; plot(angleWrapped,FS_func(:,m),'.');
    ItryFS(:,m) = stats.I(:,m)./FS_func(:,m);
    
    % ItryFS = -IcorrFS(1:min(length(IcorrFS),length(laserSum)))./(smooth(laserSum(1:min(length(IcorrFS),length(laserSum))),10)-darkSignalXsum); % 0.049 is a dark signal value measured Feb 2012
    
    zEvNano(:,m) = -zDecay*log(stats.I(:,m));
    zFSCorr(:,m) = -zDecay*log(ItryFS(:,m));
    
    Imap = accumarray(round(1000+[xc(:,m),yc(:,m)]),stats.I(:,m));
    ImapCorr = accumarray(round(1000+[xc(:,m),yc(:,m)]),ItryFS(:,m));
    Iweights = accumarray(round(1000+[xc(:,m),yc(:,m)]),1);
    Imap = Imap./Iweights;
    ImapCorr = ImapCorr./Iweights;
    
    [psdz{m} fz{m}] = pwelch(subPoly(zEvNano(:,m),0),[],[],[],fs);
    [psdzcorr{m} fz{m}] = pwelch(subPoly(zFSCorr(:,m),0),[],[],[],fs);
%     [az(m) foz(m)] = lorenzFit(fz{m}(10:end),psdz{m}(10:end));
%     [azfs(m) fozfs(m)] = lorenzFit(fz{m}(10:end),psdzcorr{m}(10:end));

%     figure;
    [r_meas(m) sigma(m)] = riceFit(sqrt(xc(:,m).^2+yc(:,m).^2));
    
end


nm = 1E-9;
pN = 1E-12;
C_th = 410*pN*nm*nm;

statspp.time = time;
statspp.cx_dc = cx_dc;
statspp.cy_dc = cy_dc;
statspp.angle = angle;
statspp.psd = psd;
statspp.f = f;
statspp.ItryFS = ItryFS;
statspp.zFSCorr = zFSCorr;
statspp.zEvNano = zEvNano;
statspp.a = a;
statspp.fo = fo;
statspp.psdz = psdz;
statspp.fz = fz;
statspp.psdzcorr = psdzcorr;
statspp.FS_coeffs = FS_coeffs;
statspp.FS_func = FS_func;
statspp.Imap = Imap;
statspp.ImapCorr = ImapCorr;
statspp.yc = yc;
statspp.xc = xc;
statspp.eStruct = eStruct;
statspp.gamma_meas = kbT./(pi*pi.*a);
statspp.kappa_meas = statspp.gamma_meas.*2*pi.*fo;
statspp.r_meas = r_meas;
statspp.sigmaR = sigma;
statspp.L_meas = C_th./statspp.kappa_meas;
statspp.N_meas = statspp.L_meas/(.34*nm);

