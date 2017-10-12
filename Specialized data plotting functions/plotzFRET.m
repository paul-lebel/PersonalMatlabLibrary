
function dataStruct  = plotzFRET(results,timeRange)

% if ~iscolumn(fretData)
%     fretData = fretData';
% end

% Create figure
figure1 = figure;

% % Create axes
% axes1 = subplot(3,1,1);
% box(axes1,'on');
% grid(axes1,'on');
% hold(axes1,'all');

if nargin<2
    inds = 1:length(results.time);
%     donorInds = 1:size(fretData,1);
else
    inds = find(results.time > timeRange(1) & results.time < timeRange(2));
%     donorInds = find(fretData(:,1) > timeRange(1) & fretData(:,1) < timeRange(2));
end

fs = 1/(results.time(2)-results.time(1));

tgood = results.time(inds)-results.time(inds(1));

zOffset = mean(results.zFSCorr(inds(1:2000)));
zgood = results.zFSCorr(inds)-mean(results.zFSCorr(inds(1:2000)));
zsm1 = zplp(results.zFSCorr,fs,100)-zOffset;
zsm1 = zsm1(inds);
zsm2 = zplp(results.zFSCorr(inds),fs,5)-zOffset;
% zsm2 = zplp(z,fs,round(fs/500))-zOffset;

% subplot(2,1,2);

% Create axes
axes2 = subplot(2,1,1);
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

zOut = [zgood zsm1 zsm2];

% Create axes
axes2 = subplot(2,1,2);
box(axes2,'on');
grid(axes2,'on');
hold(axes2,'all');
plot(tgood,results.FRET(inds),'b','linewidth',2);
% plot(tgood,results.acceptor(inds),'r','linewidth',2);
xlim([0 tgood(end)]);
ylim([-.1 1.2]);

dataStruct.time = tgood;
dataStruct.z = zOut;
dataStruct.FRET = results.FRET(inds);