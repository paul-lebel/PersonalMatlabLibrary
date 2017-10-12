% Generate Fourier coefficients for a data trace
% order of coeffs is a0 a1 b1 a2 b2 a3 b3 a4 b4

function [coeffs fdata] = Fcoeffs4(x,y)

coeffs(1) = sum(y(2:end).*cos(0*x(2:end)).*diff(x))/(2*pi);

coeffs(2) = sum(y(2:end).*cos(x(2:end)).*diff(x))/pi;
a2 = sum(y(2:end).*cos(2*x(2:end)).*diff(x))/pi;
a3 = sum(y(2:end).*cos(3*x(2:end)).*diff(x))/pi;
a4 = sum(y(2:end).*cos(4*x(2:end)).*diff(x))/pi;

b1 = sum(y(2:end).*sin(1*x(2:end)).*diff(x))/pi;
b2 = sum(y(2:end).*sin(2*x(2:end)).*diff(x))/pi;
b3 = sum(y(2:end).*sin(3*x(2:end)).*diff(x))/pi;
b4 = sum(y(2:end).*sin(4*x(2:end)).*diff(x))/pi;

