
% Compute the (intensity) fresnel reflection and transmission coefficients 
% for both s- and p- polarizations. n1, n2 can be complex but result is
% real-valued.

% Author: Paul Lebel
% 12/22/2015

% 

function [Rs, Ts, Rp, Tp] = fresnel_s(theta_incident,n1,n2)
theta_trans = asin((n1/n2)*sin(theta_incident));

if ~isreal(theta_trans)
    error('TIR will occur');
end

Rs = abs((n1*cos(theta_incident) - n2*cos(theta_trans))./(n1*cos(theta_incident) + n2.*cos(theta_trans))).^2;
Rp = abs((n1*cos(theta_trans) - n2*cos(theta_incident))./(n1*cos(theta_trans) + n2*cos(theta_incident))).^2;

Ts = 1-Rs;
Tp = 1-Rp;
