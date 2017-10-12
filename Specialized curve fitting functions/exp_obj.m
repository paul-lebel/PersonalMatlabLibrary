function f = exp_obj(X,t,s)

% X(i) are the parameters you are searching for
% Change this to the function you would like to fit

f = sum( (X(1)*(1-exp(-t/X(2))) - s).^2 );

return

