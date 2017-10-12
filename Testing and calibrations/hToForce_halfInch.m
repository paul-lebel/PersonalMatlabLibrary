function F = hToForce_halfInch(h,flag)
nIn = nargin;

data = load('C:\Users\Zev Bryant\Documents\MATLAB\Paul\Testing and calibrations\Calibration data\ForceSimData.mat');

if nIn > 1
    h = 23.3-h; % 23.3mm is the emperically determined contact point for the magnets and the coverslip
else
    h = 24.65-h;
end

F = interp1(data.hhi,data.Fhi,h);