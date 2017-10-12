
function h = Ftoh_halfInch(F)

data = load('C:\Users\Zev Bryant\Documents\MATLAB\Paul\Testing and calibrations\Calibration data\ForceSimData.mat');

maxInd = find(data.Fhi == max(data.Fhi));

Fhi = data.Fhi(1:maxInd);
hhi = data.hhi(1:maxInd);

h = interp1(Fhi,hhi,F);

% h = 23.3 -h;
% h = 24.65 - h;
h = 15.56 - h;  % October 21st 2014 collision point