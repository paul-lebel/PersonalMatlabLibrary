
clear laserData;
clear digData;
numRates = 10;
laserData = zeros(50000,numRates);
digData = zeros(50000,numRates);
dt = 1/10000;
t = dt:dt:50000*dt;
rate = logspace(0,log10(50),numRates);


for i=1:numRates
    
tempData = square(2*pi*rate(i)*t,50);
tempData = tempData > 0;
digData(:,i) = double(tempData);

s.queueOutputData(digData(:,i))
laserData(:,i) = s.startForeground;
pause(.5);

end

for i=1:10
    ldataSmooth(:,i) = zplp(laserData(:,i),10000,2*rate(i));
end

plot(t,ldataSmooth);