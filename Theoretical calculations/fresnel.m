
% Compute and plot the electric field components during TIR

% Author: Paul Lebel
% 9/25/2017

% Input arguments:
% n1 = refractive index of first media
% n2 = refractive index of second media
% Es = amplitude of the s- component (real or complex)
% Ep = amplitude of the p- component (real or complex)
% NA = max. NA of the objective

% Output arguments
% theta_i is a vector of incident angles (rad) from 0 to asin(NA/n1) (max).
% Et contains complex field amplitudes [Ex, Ey, Ez] for each incident angle
% in vector theta_i

function [theta_i, Et] = fresnel(n1,n2, Es, Ep, NA)

theta_max = asin(NA/n1);
theta_i = linspace(0,theta_max,1000);
theta_t = asin((n1./n2).*sin(theta_i));
theta_c = asin(n2/n1);
indC = find(theta_i > theta_c,1);


% Work out power transmission coefficients
Rs = abs((n1.*cos(theta_i) - n2.*cos(theta_t))./(n1.*cos(theta_i) + n2.*cos(theta_t))).^2;
Rp = abs((n1.*cos(theta_t) - n2.*cos(theta_i))./(n1.*cos(theta_t) + n2.*cos(theta_i))).^2;

Ts = 1-Rs;
Tp = 1-Rp;

% Work out field transimission coefficients
rs = (n1.*cos(theta_i) - n2.*cos(theta_t))./(n1.*cos(theta_i) + n2.*cos(theta_t));
rp = (n2.*cos(theta_i) - n1.*cos(theta_t))./(n1.*cos(theta_t) + n2.*cos(theta_i));

ts = 2*n1.*cos(theta_i)./(n1.*cos(theta_i)+n2.*cos(theta_t));
tp = 2*n1.*cos(theta_i)./(n1.*cos(theta_t)+n2.*cos(theta_i));

Ex = Ep.*tp.*(-i).*sqrt( ((n1/n2)*sin(theta_i)).^2 - 1);
Ey = Es.*ts;
Ez = Ep.*tp.*(n1./n2).*sin(theta_i);

figure;
plot(n1*sin(theta_i), Rs,'-b','linewidth',2); hold all;
plot(n1*sin(theta_i), Ts,'--b','linewidth',2); 
plot(n1*sin(theta_i), Rp,'-r','linewidth',2); hold all;
plot(n1*sin(theta_i), Tp,'--r','linewidth',2); 
xlabel('Incident NA');
ylabel('Power Reflection/Transmission');
legend('Rs','Ts', 'Rp','Tp');
xlim([1, n1*sin(theta_max)]);
title(['Fresnel power coefficients for n_1 = ' num2str(n1), ', n_2 = ', num2str(n2)]);


% figure;
% subplot(2,1,1);
% plot(theta_i*180/pi, abs(rs),'-b','linewidth',2); hold all;
% plot(theta_i*180/pi, abs(ts),'--b','linewidth',2); 
% plot(theta_i*180/pi, abs(rp),'-r','linewidth',2); hold all;
% plot(theta_i*180/pi, abs(tp),'--r','linewidth',2); 
% xlabel('Incident angle (degrees)');
% ylabel('Reflection/Transmission');
% title(['Electric field amplitude for n_1 = ' num2str(n1), ', n_2 = ', num2str(n2)]);
% legend('rs','ts', 'rp','tp');
% xlim([0 theta_max*(180/pi)]);
% 
% subplot(2,1,2);
% plot(theta_i*180/pi, angle(rs),'-b','linewidth',2); hold all;
% plot(theta_i*180/pi, angle(ts),'--b','linewidth',2); 
% plot(theta_i*180/pi, angle(rp),'-r','linewidth',2); hold all;
% plot(theta_i*180/pi, angle(tp),'--r','linewidth',2); 
% xlabel('Incident angle (degrees)');
% ylabel('Reflection/Transmission');
% legend('rs','ts', 'rp','tp');
% title(['Electric field phase shift for n_1 = ' num2str(n1), ', n_2 = ', num2str(n2)]);
% xlim([0 theta_max*(180/pi)]);


figure;
subplot(2,1,1);
plot(n1*sin(theta_i), abs(Ex),'linewidth',2); hold all;
plot(n1*sin(theta_i), abs(Ey),'linewidth',2);
plot(n1*sin(theta_i), abs(Ez),'linewidth',2); 
legend('abs(Ex)','abs(Ey)', 'abs(Ez)');
ylabel('Relative field magnitude','fontsize',14);
title('Electric field amplitudes','fontsize',14);
xlim([1, n1*sin(theta_max)]);

subplot(2,1,2);
plot(n1*sin(theta_i), angle(Ex),'linewidth',2); hold all;
plot(n1*sin(theta_i), angle(Ey),'linewidth',2);
plot(n1*sin(theta_i), angle(Ez),'linewidth',2); 
xlabel('Incident NA','fontsize',14);
ylabel('Phase shift (rad)');
legend('angle(Ex)','angle(Ey)', 'angle(Ez)');
xlim([1, n1*sin(theta_max)]);

figure;
thisAngle = .5*(theta_max + theta_c);
indMid = find(theta_i > thisAngle,1);
phi = linspace(0, 2*pi, 40);
eVec_c(:,1) = real(Ex(indC)*exp(1i*phi));
eVec_c(:,2) = real(Ey(indC)*exp(1i*phi));
eVec_c(:,3) = real(Ez(indC)*exp(1i*phi));
eVec_mid(:,1) = real(Ex(indMid)*exp(1i*phi));
eVec_mid(:,2) = real(Ey(indMid)*exp(1i*phi));
eVec_mid(:,3) = real(Ez(indMid)*exp(1i*phi));
eVec_max(:,1) = real(Ex(end)*exp(1i*phi));
eVec_max(:,2) = real(Ey(end)*exp(1i*phi));
eVec_max(:,3) = real(Ez(end)*exp(1i*phi));

plot3(eVec_c(:,1), eVec_c(:,2), eVec_c(:,3),'o'); hold all;
plot3(eVec_mid(:,1), eVec_mid(:,2), eVec_mid(:,3),'o'); hold all;
plot3(eVec_max(:,1), eVec_max(:,2), eVec_max(:,3),'o'); hold all;
xlabel('X','fontsize',16);
ylabel('Y','fontsize',16);
zlabel('Z','fontsize',16);
title('Evanescent wave polarization elipse');
legend('Critial angle','Middle angle','Max angle')
grid;
axis equal;

Et = [Ex', Ey', Ez'];