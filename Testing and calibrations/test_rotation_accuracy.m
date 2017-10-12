

% ret = SetImage(1,1,cropVec(1),cropVec(2),cropVec(3),cropVec(4));
imagesPerPhi = 30000;
xsize = 10;
ysize = 10;
framesize = xsize*ysize;
imagedata = zeros(xsize,ysize,imagesPerPhi);

xnow = readX(1); % Current piezo position x
ynow = readY(1); % Current piezo position y
xSet = 4.3;
ySet = 4.3;

% Zero the magnets
magnetAngle_obj.VEL('1',90);
setMagnets(magnetAngle_obj,0);

phi = 0:30:(3600-30);
phiPerRot = round(360/mean(diff(phi)));
totalRepeats = round(phi(end)/360);
% phi = [ [0:90:1800], [ 1710:-90:0]];

% angleFig = figure;
imageFig = figure;

left = zeros([xsize,ysize, imagesPerPhi*numel(phi)]);
clear stats;
params = zeros(imagesPerPhi,6);
stats.cx = zeros(size(left,3),1);
stats.cy = stats.cx; stats.sx = stats.cx; stats.sy = stats.cx; 
stats.I = stats.cx; stats.h = stats.cx; stats.Offset = stats.cx;

[ret]=SetShutter(0, 1, 50, 50);                 %   Close the shutter

for i=1:numel(phi)
    % Move the piezo to the ith position and wait for the motion to finish
    setMagnets(magnetAngle_obj,phi(i));
    while(abs(magnetAngle_obj.qMOV('1')-magnetAngle_obj.qPOS('1')) > .1)
        pause(.05);
    end
    
    % Frame index
    ind1 = (i-1)*imagesPerPhi+1;
    ind2 = i*imagesPerPhi;
    
    imagedata = returnNFrames(xsize,ysize,imagesPerPhi);
    left(:,:,ind1:ind2) = imagedata;
    set(0,'CurrentFigure',imageFig);
    
    subplot(2,1,1);
    imagesc(left(:,:,ind2)); axis image;
    
    
    params = gsolve2d(double(imagedata(:)),[xsize ysize]);
    stats.cx(ind1:ind2) = params(:,3);
    stats.cy(ind1:ind2) = params(:,4);
    stats.sx(ind1:ind2) = params(:,5);
    stats.sy(ind1:ind2) = params(:,6);
    stats.h(ind1:ind2) = params(:,2);
    stats.Offset(ind1:ind2) = params(:,1);
    stats.I(ind1:ind2) = stats.sx(ind1:ind2).*stats.sy(ind1:ind2).*stats.h(ind1:ind2);
    
    subplot(2,1,2);
    plot(stats.cx(ind1:ind2),stats.cy(ind1:ind2),'.'); axis equal;
    
    [ydrift xdrift ro] = circleFit(stats.cx(ind1:ind2),stats.cy(ind1:ind2));
    xnow = xnow + .5*(xdrift-xSet)*.105;
    ynow = ynow + .5*(ydrift-ySet)*.105;
    piezoX(mcl_handle,xnow);
    piezoY(mcl_handle,ynow);
    
end

[ret]=SetShutter(0, 2, 50, 50);                 %   Close the shutter
% Reduce the force
setForce(magnetHeight_obj, 0.5);
s.stop;
qPOS = magnetAngle_obj.qPOS('1');
deltaPOS = mod(qPOS,360);
newPOS = qPOS - deltaPOS;
magnetAngle_obj.MOV('1',newPOS);
magnetAngle_obj.POS(axisname2,0);


% time = Kinetic:Kinetic:numel(phi)*imagesPerPhi*Kinetic;


results = batchPostProcessNoPSD(stats,Kinetic);
results.angle = reshape(results.angle,round(numel(results.angle)/numel(phi)),numel(phi));
dims = size(results.angle);

results.angleRot = -results.angle/(2*pi);
results.angleRot = results.angleRot - mean(results.angleRot(:,1));


meanAngleRot = mean(results.angleRot,1);
meanAngleWrapped = meanAngleRot - floor(phi/360);
meanAngleWrapped2 = accumarray( repmat( [1:round(360/mean(diff(phi)))]',[round(phi(end)/360) 1]),meanAngleWrapped)/totalRepeats;
meanAngleWrapped = meanAngleWrapped - meanAngleWrapped2(1);
results.angleRot = results.angleRot - meanAngleWrapped2(1);
meanAngleWrapped2 = accumarray( repmat( [1:round(360/mean(diff(phi)))]',[round(phi(end)/360) 1]),meanAngleWrapped)/totalRepeats;
mmAngleWrapped = reshape(meanAngleWrapped,[phiPerRot totalRepeats]);
errorTest = std(mmAngleWrapped,[],2)/sqrt(totalRepeats);

pFit = polyfit(phi(1:phiPerRot),meanAngleWrapped2'*360,1);
meanAngleWrapped3 = meanAngleWrapped2-pFit(2)/360;
meanAngleWrapped = meanAngleWrapped-pFit(2)/360;

figure;
plot(mod(phi,360),meanAngleWrapped*360,'x','color',[.5 .5 .5],'markersize',8,'linewidth',1)
hold all;
plot(phi(1:phiPerRot),phi(1:phiPerRot),'r-','linewidth',2);
errorbar(phi(1:phiPerRot),meanAngleWrapped3*360,errorTest*360,'b.','markersize',20,'linewidth',2)
ylabel('Measured rotor bead angle (degrees)','fontsize',10)
xlabel('Commanded magnet angle (degrees)','fontsize',10);
legend('Raw data','y = x','Mean of raw data','Location','Northwest')
xlim([-25 360]);
ylim([-25 360]); 
set(gca,'XTick',[0:60:360])
set(gca,'YTick',[0:60:360])
axis square;

subplot(4,1,4);
bar(phi(1:phiPerRot), meanAngleWrapped3*360-phi(1:phiPerRot)');
ylim([-15 15]);  xlim([-25 360])
hold all;
plot(phi(1:phiPerRot),mean(errorTest*360)*ones(12,1),'k--');
plot(phi(1:phiPerRot),-mean(errorTest*360)*ones(12,1),'k--');

% 
figure;
% 
% for i=1:numel(phi)
%     results.angleRot(:,i) = results.angleRot(:,i) + round(phi(i)/360 - mean(results.angleRot(:,i)));
%     plot(Kinetic*((1+(imagesPerPhi+20000)*(i-1)):(imagesPerPhi+(imagesPerPhi+20000)*(i-1))),results.angleRot(:,i),'color',[.7 .8 1])
%     hold on;
%     plot(Kinetic*((1+(imagesPerPhi+20000)*(i-1)):(imagesPerPhi+(imagesPerPhi+20000)*(i-1))),zplp(results.angleRot(:,i),1/Kinetic,5),'r','linewidth',2);
%     plot(Kinetic*((1+(imagesPerPhi+20000)*(i-1)):(imagesPerPhi+(imagesPerPhi+20000)*(i-1))), ones(imagesPerPhi,1)*phi(i)/360,'-k','linewidth',2)
% end

tplot = zeros(imagesPerPhi,numel(phi)); 
angLP = tplot; angCom = tplot;
for i=1:numel(phi)
    ind1 = 50000*(i-1)+1;
    ind2 = ind1+(30000-1);
    tplot(:,i) = Kinetic*[ind1:1:ind2];
    angLP(:,i) = zplp(results.angleRot(:,i),1/Kinetic,5);
    angCom(:,i) = ones(imagesPerPhi,1)*phi(i)/360;
end
tplot = reshape(tplot,[numel(tplot) 1]);
plot(tplot,results.angleRot(:),'color',[.7 .8 1]); hold all;
plot(tplot,angLP(:),'r');
plot(tplot,angCom(:),'k');
axis tight;
xlabel('Time (s)','fontsize',16);
ylabel('Angle (rotations)','fontsize',16);
set(gca,'XTick',[0:200:800]);
set(gca,'YTick',[0:2:10]);
