
function [RMSth W] = getRMSth(tau,kappa)

W = logspace(-6,5,1000);
kbT = 4.07E-21;


RMSth  = sqrt((2*kbT/kappa)*( tau./W - (tau^2./(W.^2)).*(1-exp(-W/tau))));