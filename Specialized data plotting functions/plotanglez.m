
function dataStruct  = plotanglez(results,inds)

% Create figure
figure1 = figure;

% Create axes
axes1 = axes('Parent',figure1,'Position',[0.13 0.518232044198895 0.775 0.461878453038675]);

box(axes1,'on');
grid(axes1,'on');
hold(axes1,'all');

if nargin<2
    inds = 1:length(results.time);
end

fs = 1/(results.time(2)-results.time(1));

anglesm = zplp(results.angle,fs,50);
anglesm2 = zplp(results.angle,fs,10);
anglegood = (results.angle(inds)-mean(results.angle(inds(1:2000))))/(2*pi);
anglegoodsm = (anglesm(inds)-mean(anglesm(inds(1:2000))))/(2*pi);
anglegoodsm2 = (anglesm2(inds)-mean(anglesm2(inds(1:2000))))/(2*pi);
ymax= round(mean(anglegood((end-1000):end)));
ymin = round(mean(anglegood(1:1000)));
% figure;

tgood = results.time(inds)-results.time(inds(1));

% subplot(2,1,1);
plot(tgood,anglegood,'color',[.7 .8 1]); hold all;
plot(tgood,anglegoodsm,'r','linewidth',1.5);
plot(tgood,anglegoodsm2,'k','linewidth',1.5);
set(gca,'YTick',[-2:2:ymax]);
% set(gca,'XTicklabel',[]);
% ylim([ymin-2, ymax+2]);
ylabel('Cumulative rotations','fontsize',13);
xlim([0 tgood(end)]);

grid on;

zOffset = mean(results.zFSCorr(inds(1:2000)));
zgood = results.zFSCorr(inds)-mean(results.zFSCorr(inds(1:2000)));
zsm1 = zplp(results.zFSCorr,fs,round(fs/50))-zOffset;
zsm1 = zsm1(inds);
zsm2 = zplp(results.zFSCorr(inds),fs,5)-zOffset;
% zsm2 = zplp(z,fs,round(fs/500))-zOffset;

% subplot(2,1,2);

% Create axes
axes2 = axes('Parent',figure1,...
    'Position',[0.13 0.11 0.775 0.364033149171271]);
% Uncomment the following line to preserve the X-limits of the axes
% xlim(axes2,[0 16.9991016450804]);
box(axes2,'on');
grid(axes2,'on');
hold(axes2,'all');


plot(tgood,zgood,'color',[.7 .8 1]);
xlabel('Time (s)','fontsize',13);
ylabel('z (nm) ','fontsize',13);
grid on;
hold all;
plot(tgood,zsm1,'color',[1 0  0],'linewidth',1.5);
xlim([0 tgood(end)]);
plot(tgood,zsm2,'k','linewidth',2);
% ylim([-80 60])
% set(gca,'Ytick',[-40 -20 0]);

thetaOut = [anglegood, anglegoodsm];
zOut = [zgood zsm1 zsm2];

dataStruct.time = tgood;
dataStruct.angle = thetaOut;
dataStruct.z = zOut;