

% Test the capabilities of the laser shutter by ramping the frequency of a
% square wave logarithmically from 1 Hz to 100 Hz.

rates = logspace(,2,10);

if exist('s');
    delete(s);
    clear s;
end

s = daq.createSession('ni');
s.Rate = 10000;
s.addAnalogInputChannel('Dev2','ai2','Voltage');
s.addCounterOutputChannel('Dev2','ctr1','PulseGeneration');
s.addDigitalChannel('Dev2','port0/line7','InputOnly');
s.DurationInSeconds = 5;
N = s.Rate*s.DurationInSeconds;

laserData = zeros(N,numel(rates));
digitalData = laserData;
tempData = zeros(N,2);

dt = 1/s.Rate;
time = dt:dt:dt*N;

for i=1:numel(rates)
    pause(.5);
    s.Channels(2).Frequency = rates(i);
    tempData = s.startForeground();
    laserData(:,i) = tempData(:,1);
    digitalData(:,i) = tempData(:,2); 
end

