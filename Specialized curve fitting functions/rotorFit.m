function [params N P] = rotorFit(cx,cy);

% The 7 fit params are (in order) 
% xo,yo,ro,sigx,sigy,theta0,sigtheta 
% N is the density map of measured rotor positions
% P is the best-fit probability distribution

%   Adapted from: Marc Lebel 03/11/2005
%   By Paul Lebel

%   Check inputs
if nargin < 2
    error('Insufficient Input')
end


%   Six parameter fit
%   Set Initial guesses

[xguess yguess rguess] = circleFit(cx,cy);
cr = sqrt( (cx-xguess).^2 + (cy-yguess).^2);

% Filter inputs by throwing away points with large errors
inds = find(cx>(-1.5*rguess) & cx<(1.5*rguess) & cy>(-1.5*rguess) ...
    & cy<(1.5*rguess));

cy = cy(inds);
cx = cx(inds);

angle = atan2(cy,cx);


[a xout] = hist(angle,100);
indmax = find(a ==max(a),1);
tguess = xout(indmax);

sx = std(cx); sy = std(cy); maxx = max(cx); minx = min(cx);
maxy = max(cy); miny = min(cy);

xo = [xguess,yguess,rguess,std(cr),tguess,1.7]

% Set upper and lower bounds on your parameters
xub = [maxx,maxy,maxx-minx,maxx-minx,tguess+8,3];
xlb = [minx,miny,0,0,tguess-8,.5];


% cx and cy must be column vectors:
if ~iscolumn(cx)
    cx = cx';
end
if ~iscolumn(cy)
    cy = cy';
end


% convert cx and cy into a 2D density map. 
[N C] = hist3([cy cx],[100 100]);
c1 = C{1};
c2 = C{2};

% Set options
options = optimset('Algorithm','interior-point','TolFun',1e-8,'TolCon',1e-8,'MaxIter',500,'MaxFunEvals',100000,...
    'TolX',1e-10,'LargeScale','on','Display','off');

%   Iterative minimization
[X,fval,flag] =fmincon('rotor_obj',xo,[],[],[],[],xlb,xub,[],options,cx,cy);

%   Assign output variables
params.xo = X(1);
params.yo = X(2);
params.ro = X(3);
params.sx = X(4);
params.t0 = X(5); %mod(pi+X(5),2*pi) - pi;
params.st = X(6);

%   Check for fitting errors
if flag < 1 || sum( X > xub) || sum( X < xlb)
    disp('Fitting Error...');
end


P = rotorSmear_s(X,[100 100]);
