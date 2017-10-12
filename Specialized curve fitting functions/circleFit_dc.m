function [cx,cy,r] =circleFit_dc(x,y);

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
xo = [0 0 45];

% Set upper and lower bounds on your parameters
xub = [2000 2000 1000];
xlb = [-500 -500 0];

%   Set options
options = optimset('Algorithm','interior-point','TolFun',1e-6,'TolCon',1e-6,'MaxIter',5000,'MaxFunEvals',50000, ...
    'TolX',1e-6,'LargeScale','on','Display','off');

%   Iterative minimization
[X,fval,flag] =fmincon('circle_obj',xo,[],[],[],[],xlb,xub,[],options,x,y);

%   Assign output variables
cx = X(1);
cy = X(2);
r = X(3);
% d = X(4);


%   Plot (comment out if desired)
% plot(x,y,'rs',x,X(1)*x.^3 + X(2)*x.^2 + X(3)*x,'b');
% set(gca,'Xlim',[min(x) max(x)]);


%   Check for fitting errors
if flag >= 1 && cx >= xlb(1) && cx <= xub(1) && cy >= xlb(2) && cy <= xub(2) ...
         && r >= xlb(3) && r <= xub(3) 
%      && d >= xlb(4) && d <= xub(4)
else
    disp('Fitting Error...');
end

