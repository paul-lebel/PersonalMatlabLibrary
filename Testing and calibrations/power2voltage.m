% Pmeter = [6.07 14.05 22.3 30.35 38.27 46.25 54.11 58.25];

% This function converts a desired laser diode power (in mW), and converts
% it into the necessary analog voltage value needed to produce that power
% by driving the 'mod' input of Thorlabs controller model ITC4001, which
% drives a 200 mW Lumics 845 nm laser diode. The function loads calibration
% data that was acquired for this system and interpolates it. 

function voltage = power2voltage(pDesired)

if numel(pDesired) > 1
    error('Only scalars allowed');
end

if (pDesired > 210)
    warning('Power out of range! 0-210 mW valid');
    voltage = 1.3;
    return;
end

if(pDesired == 0)
    voltage = -.1;
    return;
end


calData = load('C:\Users\Zev Bryant\Documents\MATLAB\Paul\Testing and calibrations\Calibration data\IR_power_calibration.mat');

voltage = interp1(calData.meterPower,smooth(calData.calVin,3),pDesired);


