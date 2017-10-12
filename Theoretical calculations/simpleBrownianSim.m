
% Simple brownian dynamics simulation

% Simulate the brownian twist dynamics of a rotor bead
pN = 1E-12;
nm = 1E-9;
kbT = 4.07*pN*nm;
eta = 0.001;
C = 410*pN*nm*nm;
% L = 0.34*nm*[450 450 800 3400];
L = 0.34*nm*450;

tmax = 10;
dt = 10E-6;
t = dt:dt:tmax;

theta = zeros(numel(t),numel(L));

% r_bead = 0.5*[75 140 300 700]*nm;
% r_bead = 0.5*75*nm;

for k=1:numel(L)
    
%     kappa = C/L(k);
    kappa = 2.87E-5;
    gamma_bead = 1.78E-8;
%     gamma_bead = 14*pi*eta*r_bead(k)^3;

    inv_gamma_bead = 1/gamma_bead;
    
    thermaltorque = sqrt(2*gamma_bead*kbT/dt)*randn(numel(t),1);
    
    for i=2:numel(t)
        thetadot = (-kappa*theta(i-1,k) + thermaltorque(i))*inv_gamma_bead;
        theta(i,k) = theta(i-1,k) + thetadot*dt;
    end
    
    [psd(:,k) f(:,k)] = pwelch(theta(:,k),[],[],[],1/dt);
    
    plot(t,theta); hold all;
    plot(t,zplp(theta,1/dt,1),'k','linewidth',2);
    
end

% 
