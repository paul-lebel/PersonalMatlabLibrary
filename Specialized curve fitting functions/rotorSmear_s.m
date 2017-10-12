% Function to compute the expected distribution of rotor bead positions in
% the image plane. Fitting rotor bead data to this function has become
% increasingly important as I push the assay to work at the edge of
% trackability. Fitting data to a circle begins to fail as angular variance
% gets smaller and force gets lower.

% It is my hope that fitting to this function will allow better
% center-tracking of the distribution, as well as fitting the mean angle of
% the distribution.

% Author: Paul Lebel
% Date: June 29th, 2011

function  P = rotorSmear_s(params,res)

xo = params(1);
yo = params(2);
ro = params(3);
sigx = params(4);
sigy = sigx;    % sigy = params(5);
t0 = params(5);
sigt = params(6);


% ro = radius of rotor bead
% sigr = standard deviation of lateral motion
% sigt = standard deviation of twist
% res = grid resolution to output; res(1) is xres, res(2) is yres
% recommended value for res is ~[100,100] 

% xmin = xo - ro - 4*sigx;
% xmax = xo + ro + 4*sigx;
% ymin = yo - ro - 4*sigy;
% ymax = yo + ro + 4*sigy;

xmin = xo-1.5*ro;
xmax = xo+1.5*ro;
ymin = yo-1.5*ro;
ymax = yo+1.5*ro;

xrange = linspace(xmin,xmax,res(1));
yrange = linspace(ymin,ymax,res(2));
trange = linspace(t0-4*sigt,t0+4*sigt,250); % 250 is arbitrary

dx = (xmax-xmin)/(res(1)-1);
dy = (ymax-ymin)/(res(2)-1);

% [X Y T] = ndgrid(xrange,yrange,trange);
[X Y T] = meshgrid(xrange,yrange,trange);

integrand = exp( -(T-t0).^2/(2*sigt^2) ...
    - (X-xo-ro*cos(T)).^2/(2*sigx^2) ...
    - (Y-yo-ro*sin(T)).^2/(2*sigy^2));

% Xout = X(:,:,1);
% Yout = Y(:,:,1);

clear X Y T xrange yrange trange xmin xmax ymin ymax

P = sum(integrand,3);
ssum = sum(P(:));
P = P/ssum;
end