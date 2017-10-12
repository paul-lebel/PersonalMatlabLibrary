function plotResults(results)

prev2 = figure('Position',[500 600 900 380]);

set(0,'CurrentFigure',prev2);
subplot(2,3,1);
relateC(results.xc,results.yc,80); axis square; axis equal;

subplot(2,3,2);
plot(results.time,results.angle);
xlabel('Time (s)','fontsize',13);
ylabel('Angle (rad)','fontsize',13);

subplot(2,3,3);
dt = results.time(2)-results.time(1);
psdStats = psdAnalysis(results.angle,dt,5); axis tight;
xlabel('Frequency (Hz)','fontsize',14);
ylabel('Noise power spectral density (rad^2/Hz)','fontsize',14);
title('Angular PSD','fontsize',14);
% xlabel('Frequency (Hz)','fontsize',12);
% ylabel('Angular noise power spectral density (rad^2/Hz)','fontsize',12)

subplot(2,3,5);
plot(results.time,results.zFSCorr,'color',[.7 .8 1]);
hold all;
plot(results.time,zplp(results.zFSCorr,2000,50),'r');
xlabel('Time (s)','fontsize',12);
ylabel('z (nm, uncalibrated)','fontsize',12);

subplot(2,3,6);
zpsdStats = psdAnalysis(results.zFSCorr,dt,5); 
hold all;
zpsdStats_raw = psdAnalysis(results.zEvNano,dt,5);
axis tight;
xlabel('Frequency (Hz)','fontsize',14);
ylabel('Noise power spectral density (nm^2/Hz)','fontsize',14);
title('Extension PSD','fontsize',14);

% hist(zplp(results.zFSCorr,2000,50),100);
% hist(results.zFSCorr,100)
% xlabel('z (nm, uncalibrated)','fontsize',12);
% ylabel('Counts','fontsize',12);

subplot(2,3,4);
axis([0 1 0 1]);
text(0.2,0.8,['\kappa = ' num2str((1E21)*psdStats.kappa,'%5.3f') ' pN nm/rad']);
text(0.2,0.7,['\gamma = ' num2str((1E21)*psdStats.gamma,'%5.3f') ' pN nm s']);
text(0.2,0.6,['\tau = ' num2str(psdStats.tau,'%5.3f') ' s']);
text(0.2,0.5,['nBasesTh = ' num2str(psdStats.nBasesTh,'%5.3f') ' bp']);
text(.2, 0.4,['Bead size (riceFit) = ' num2str(2*results.r_meas)]);