function [a,rate] =msdFit(x,y);

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
xo = [600 1000];

% Set upper and lower bounds on your parameters
xub = [10000000 500000];
xlb = [0 0];

%   Set options
options = optimset('Algorithm','interior-point','TolFun',1e-6,'TolCon',1e-6,'MaxIter',500,'MaxFunEvals',100000,...
    'TolX',1e-6,'LargeScale','on','Display','off');

%   Iterative minimization
[X,fval,flag] =fmincon('msd_obj',xo,[],[],[],[],xlb,xub,[],options,x,y);

%   Assign output variables
a = X(1);
rate = X(2);

% d = X(4);


%   Plot (comment out if desired)
% plot(x,y,'rs',x,X(1)*x.^3 + X(2)*x.^2 + X(3)*x,'b');
% set(gca,'Xlim',[min(x) max(x)]);


%   Check for fitting errors
if flag >= 1 && a >= xlb(1) && a <= xub(1) && rate >= xlb(2) && rate <= xub(2) 
         %&& r >= xlb(3) && r <= xub(3) 
%      && d >= xlb(4) && d <= xub(4)
else
    disp('Fitting Error...');
end

