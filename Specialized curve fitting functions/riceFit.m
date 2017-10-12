function [ro sigma]  =riceFit(radius);

%   ro is the actual off-center radius of the distribution
%   sigma is the Gaussian spread's std
%   Adapted from: Marc Lebel 03/11/2005
%   By Paul Lebel
%   Usage: [a,b,c,d] = functionFit(x,y)
%   Where x is independent variable and y is dependent variable


% radius is a vector of radii from either a rotor bead distribution or a
% magnetic bead spinVid

[rProb rBins] = hist(radius,100);
rProb = rProb/sum(rProb*(rBins(2)-rBins(1))); % Normalized to be a probability distribution


%   Set Initial guesses [nm]
xo = [mean(radius) std(radius)];

% Set upper and lower bounds on your parameters
xub = [100000 100000];
xlb = [0 0];

%   Set options
options = optimset('Algorithm','interior-point','TolFun',1e-10, ...
    'TolCon',1e-10,'MaxIter',10000,'MaxFunEvals',10000, ...
    'TolX',1E-10,'Display','off');

%   Iterative minimization
[X,fval,flag] =fmincon('rice_obj',xo,[],[],[],[],xlb,xub,[],options,rBins,rProb);

%   Assign output variables
ro = X(1);
sigma = X(2);

%   Plot (comment out if desired)
xfit = linspace(min(rBins),max(rBins),200);
yfit = (xfit/(sigma^2)).*exp(-(xfit.^2+ ro^2)/(2*sigma^2)).*besseli(0,xfit*ro/(sigma^2));

% plot(rBins,rProb,'o','linewidth',2); hold all;
% plot(xfit,yfit,'-k','linewidth',2);
% 
% xlabel('Radius ','fontsize',12)
% ylabel('Probability density ','fontsize',12)

%   Check for fitting errors
if flag >= 1 && ro >= xlb(1) && ro <= xub(1) && sigma >= xlb(2) && sigma <= xub(2)
      %   && r >= xlb(3) && r <= xub(3) 
%      && d >= xlb(4) && d <= xub(4)
    disp('Fitting completed successfully');
else
    disp('Fitting Error...');
end

