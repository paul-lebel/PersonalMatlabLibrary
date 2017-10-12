
function [RMSth W] = getAllan_th(tau,kappa)

W = logspace(-6,5,1000);
kbT = 4.07E-21;
gamma = tau*kappa;

RMSth  = sqrt( (2*kbT*gamma./(kappa^2*W)).*( 1 + ((2*gamma)./(kappa.*W)).*exp(-kappa*W./gamma) - (gamma./(2*kappa*W)).*exp(-2*kappa*W/gamma) -3*gamma./(2*kappa*W))); 