function [cx cy] = rotorGen(xo,yo,ro,sigx,theta0,sigtheta,n)

xc = sigx*randn(n,1);
yc = sigx*randn(n,1);

theta = theta0 + sigtheta*randn(n,1);

cx = xo + xc + ro*cos(theta);
cy = yo + yc + ro*sin(theta);

