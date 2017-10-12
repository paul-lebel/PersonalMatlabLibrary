
% Calibrate the conversion from the PSD's intensity normalized signal into
% nm, via stepping of the piezo stage

% Shut down any previous lock that may be running
if exist('s') 
delete(s);
clear s
end


nSteps = 21;
nRepeats = 10;
range = .25; % Single-sided range, um
zo = readZ(1);
z = zo + linspace(-range,range,nSteps);

% Create daq session
s = daq.createSession('ni');

% Define input channels for position and sum signals. 
% This one is for the sum signal
s.addAnalogInputChannel('Dev2', 'ai0', 'Voltage');
% Position signal
s.addAnalogInputChannel('Dev2', 'ai1', 'Voltage');

s.Rate = 1000;
s.IsContinuous = false;
s.DurationInSeconds = .2;

nPoints = s.DurationInSeconds*s.Rate;
tempData = zeros(nPoints,2);
psdData1 = zeros(nPoints,nSteps,nRepeats);
psdData2 = psdData1;
psdSignal = psdData1;

for j = 1:nRepeats
for i=1:nSteps
    piezoZ(1,z(i));
    pause(.1);
    tempData = s.startForeground();
    psdData1(:,i,j) = tempData(1:nPoints,1);
    psdData2(:,i,j) = tempData(1:nPoints,2);
    psdSignal(:,i,j) = psdData2(:,i,j)./psdData1(:,i,j);
%     plot(psdSignal(:,1:i),'b');
%     plot(z(1:i),squeeze(mean(psdSignal(:,1:i,j),1)),'o-');
end
clear gcf
plot(squeeze(mean(psdSignal(:,1:i,1:j),1)),-1000*(z-zo),'*-','markersize',2);
end

hold all;
figure;
plot(squeeze(mean(mean(psdSignal(:,1:i,:),1),3)),-1000*(z-zo),'o','linewidth',2);

piezoZ(1,zo);