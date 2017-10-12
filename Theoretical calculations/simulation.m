
% Simulate the brownian dynamics of a Z50 experiment
pN = 1E-12;
nm = 1E-9;
kbT = 4.07*pN*nm;
eta = 0.001;
r_bead = 110*nm/2;

C = 410*pN*nm*nm;
L_trans = 4130*0.34*nm;
kappa_trans = C/L_trans;

% indices corresponding to the calculated potential energy landscape
phi_o = 2*pi*linspace(-15,5,1000);
tau_o = linspace(25,-25,1000)*pN*nm; 
dtau = tau_o(2)-tau_o(1); 
dTheta = -dtau/kappa_trans;
% theta_o = phi_o + tau_o/kappa_trans;

pTau = polyfit(tau_o,[1:1000],1);
pPhi = polyfit(phi_o,[1:1000],1);

[X Y] = meshgrid(phi_o,tau_o);

gamma_bead = 14*pi*eta*r_bead^3;
inv_gamma_bead = 1/gamma_bead;

potential_torque = -diff(potential,1,1)/dTheta;

tmax = 800;
dt = 100E-6;
t = dt:dt:tmax;

half = round(numel(t)/2);

phi = zeros(numel(t),1);
phi(1:half) = linspace(5,-15,half)*2*pi;
phi( (half+1):end) = linspace(-15,5,half)*2*pi;

torque = zeros(numel(t),1);

for k=1:1

theta = zeros(8E6,1);
theta(1) = phi(1);

thermaltorque = sqrt(2*gamma_bead*kbT/dt)*randn(numel(t),1);
% 
for i=2:numel(t)
    phiInd = round(pPhi(1)*phi(i) + pPhi(2));
    tauNow = kappa_trans*(phi(i-1) - theta(i-1));
    tauInd = round(pTau(1)*tauNow+pTau(2));
    pTorque = potential_torque(tauInd,phiInd);
    thetadot = (pTorque+thermaltorque(i))*inv_gamma_bead;
    theta(i) = theta(i-1) + thetadot*dt;
end

torque(:,k) = kappa_trans*(phi(1:i)-theta(1:i));

end

plot(torque(4E6:end)*1E21);
hold all;
plot(zplp(torque(4E6:end)*1E21,1/dt,10),'r')



