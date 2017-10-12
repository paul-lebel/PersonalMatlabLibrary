function [a fo] =lorenzFit(x,y);

%   Adapted from: Marc Lebel 03/11/2005
%   By Paul Lebel
%   Usage: [a,b,c,d] = functionFit(x,y)
%   Where x is independent variable and y is dependent variable


%   Check inputs
if nargin < 2
    error('Insufficient Input')
end

%   Set Initial guesses
xo = [100 150];

% Set upper and lower bounds on your parameters
xub = [10000000 500000];
xlb = [0 0];

%   Set options
options = optimset('Algorithm','interior-point','TolFun',1e-10,'TolCon',1e-10,'MaxIter',10000,'MaxFunEvals',10000,...
    'TolX',1e-10,'LargeScale','on','Display','off');

%   Iterative minimization
[X,fval,flag] =fmincon('lorenz_obj',xo,[],[],[],[],xlb,xub,[],options,x,y);
% [X,fval,flag] =fmincon('lorenz_obj',xo,[],[],[],[],xlb,xub,[],x,y);


%   Assign output variables
a = X(1);
fo = X(2);
% d = X(4);

%   Plot (comment out if desired)
% plot(x,y,'rs',x,X(1)*x.^3 + X(2)*x.^2 + X(3)*x,'b');
% set(gca,'Xlim',[min(x) max(x)]);


%   Check for fitting errors
if flag >= 1 && a >= xlb(1) && a <= xub(1) && fo >= xlb(2) && fo <= xub(2)
      %   && r >= xlb(3) && r <= xub(3) 
%      && d >= xlb(4) && d <= xub(4)
    disp('Fitting completed successfully');
else
    disp('Fitting Error...');
end

