% Simple brownian dynamics simulation

pN = 1E-12;
nm = 1E-9;
kbT = 4.07*pN*nm;
eta = 0.001;
C = 410*pN*nm*nm;
L = 0.34*nm*450;

tmax = 10;
dt = 10E-6;
t = dt:dt:tmax;

N = numel(t);
r_bead = 0.5*[80:5:1000]*nm;
theta = zeros(numel(t),numel(r_bead));
thetasm = theta;
randFactor = randn(numel(t),1);
angleSig = zeros(size(t))';
stepTimes = round(N*rand(3,1));
stepSize = pi;

for i=1:numel(stepTimes)
    angleSig(stepTimes(i):end) = angleSig(stepTimes(i):end) + stepSize;
end

for k=1:numel(r_bead)
    kappa = C/L;
    gamma_bead = 14*pi*eta*r_bead(k)^3;
    inv_gamma_bead = 1/gamma_bead;  
    randFactor = randn(numel(t),1);
    thermaltorque = sqrt(2*gamma_bead*kbT/dt)*randFactor;
    thermaltorque = thermaltorque + kappa*angleSig;

    for i=2:numel(t)
        thetadot = (-kappa*theta(i-1,k) + thermaltorque(i))*inv_gamma_bead;
        theta(i,k) = theta(i-1,k) + thetadot*dt;
    end
thetasm(:,k) = zplp(theta(:,k),1/dt,20);
cla;
plot(theta(:,k)); hold all; 
plot(thetasm(:,k));
pause(.01);

end
% 
% theta = theta - pi/2;
% thetasm = thetasm - pi/2;
% angleSig = angleSig - pi/2;
figure;



dir = uigetdir();
vidObj = VideoWriter([dir '\' 'dragSim.avi'],'Motion JPEG AVI');
vidObj.FrameRate = 10;
% nFrames = totalAcquired;
open(vidObj);
% figure('Position',[500 300 120 600]);
set(gcf,'Color',[1 1 1]);



for i=numel(r_bead):-1:1
cla;
plot(t,theta(:,i)/(2*pi),'color',[.7 .8 1]); hold all;
plot(t,thetasm(:,i)/(2*pi),'r','linewidth',2);
plot(t,angleSig/(2*pi),'k');
ylim([-6 12]/(2*pi));
set(gca,'YTick',[0 1 2 3]);
set(gca,'XTick',[0:2:10]);
plot(2.5,4/pi,'ok','markersize',ceil(100*r_bead(i)/(500*nm)),'linewidth',2);
text(1.3,4/pi,sprintf('%i nm rotor bead',round(2*r_bead(i)/nm)));
xlabel('Time (s)','fontsize',12);
ylabel('Cumulative rotations','fontsize',12);
pause(.001);
currFrame = getframe(gcf);
writeVideo(vidObj,currFrame);
end
close(vidObj);

 