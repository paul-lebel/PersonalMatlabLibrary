% Paul Lebel
% Last edited March 2013
% Basic PSD analysis

% Assumptions: 
% - The input data is taken at a constant sampling rate (ie.
% time points have even spacing, equal to dt.
% - The input data is from a constrained, overdamped, thermally-driven
% oscillator with a Lorentzian shaped noise power spectrum. 

% Inputs:
% data - time domain varible (angle, position, etc...)
% dt - sampling time (ex. 1/framerate)

% Dependencies: subPoly, lorenzFit, optimization toolbox

% Outputs:
% stats - stats is a structure containing a bunch of physical quantities
% computed from the Lorenztian fit to the noise power spectrum.

function stats = psdAnalysis(data,dt,nSkip)

pN = 1E-12;
nm = 1E-9;
fs = 1/dt;
tMax = dt*numel(data);
kbT = 4.07*pN*nm;

[psd, f] = pwelch(subPoly(data,0),[],[],[],fs);
[a, fo] = lorenzFit(f(nSkip:end),psd(nSkip:end));
% [a fo] = lorenzFit(f,psd);

gamma = kbT/(pi*pi*a); 
kappa = 2*pi*gamma*fo;
D = kbT/gamma;
tau = 1/(2*pi*fo);

loglog(f,smooth(psd,10),'b'); hold all;
loglog(f,a./(f.^2 + fo^2),'r');

stats.psd = psd; 
stats.f = f;
stats.a = a; 
stats.fo = fo;
stats.D = D; 
stats.gamma = gamma;
stats.kappa = kappa; 
stats.tau = tau;
stats.Lth = (410E-30)/kappa;
stats.nBasesTh = stats.Lth/(.34E-9);
stats.rBeadTh = (gamma/(14*pi*.001))^(1/3);
stats.meanTheta = mean(data);
stats.nIndMeas = tMax/(2*tau);
stats.error = sqrt((2*kbT/(kappa*1E21))*( tau./tMax - (tau^2./(tMax.^2)).*(1-exp(-tMax/tau))));