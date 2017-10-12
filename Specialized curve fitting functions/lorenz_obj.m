function f = lorenz_obj(X,t,s)

% X(i) are the parameters you are searching for
% Change this to the function you would like to fit

f = sum(( X(1)./(X(2)^2 + t.^2) - s).^2);

return

