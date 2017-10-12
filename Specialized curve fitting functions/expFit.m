function [A tau] =expFit(x,y);

%   Adapted from: Marc Lebel 03/11/2005
%   By Paul Lebel
%   Usage: [a,b,c,d] = functionFit(x,y)
%   Where x is independent variable and y is dependent variable


%   Check inputs
if nargin < 2
    error('Insufficient Input')
end


%   Four parameter fit
%   Set Initial guesses
xo = [0.15 .02];

% Set upper and lower bounds on your parameters
xub = [2000 2000];
xlb = [-100 -100];

%   Set options
options = optimset('Algorithm','interior-point','TolFun',1e-8,'TolCon',1e-8,'MaxIter',500,'MaxFunEvals',100000,...
    'TolX',1e-10,'LargeScale','on','Display','off');

%   Iterative minimization
[X,fval,flag] =fmincon('exp_obj',xo,[],[],[],[],xlb,xub,[],options,x,y);

%   Assign output variables
A = X(1);
tau = X(2);
% xo = X(3);
% d = X(4);


%   Plot (comment out if desired)
plot(x,y,'rs');
hold all;
plot(x,A*(1-exp(-x/tau)),'b');
set(gca,'Xlim',[min(x) max(x)]);


%   Check for fitting errors
if flag >= 1 && A >= xlb(1) && A <= xub(1) && tau >= xlb(2) && tau <= xub(2)
%          && xo >= xlb(3) && xo <= xub(3) 
%      && d >= xlb(4) && d <= xub(4)
else
    disp('Fitting Error...');
end

