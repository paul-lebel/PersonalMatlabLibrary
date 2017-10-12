% s = daq.createSession('ni');
% s.addAnalogInputChannel('Dev2','ai2','Voltage');
% s.addAnalogOutputChannel('Dev2','ao0','Voltage');
% s.addAnalogInputChannel('Dev2','ai3','Voltage');

% Measured intensity ratio for the OD2 filter at 845 nm
OD2Ratio = 29.4485;

calVin = linspace(-.1,1.3,500);
calVmeter = zeros(size(calVin));
calVController = calVmeter;
tempMeter = zeros(5,1); tempController = tempMeter;

for i=1:500
    s.outputSingleScan(calVin(i));
    disp(i);
    for j=1:5
        temp = s.inputSingleScan(); pause(.001);
        tempMeter(j) = temp(1);
        tempController(j) = temp(2);    
    end
    calVmeter(i) = mean(tempMeter);
    calVController(i) = mean(tempController);
end

% mW
meterPower = calVmeter*OD2Ratio/.5;
controllerCurrent = calVController;

plot(calVin,meterPower); hold all;
plot(calVin,controllerCurrent);