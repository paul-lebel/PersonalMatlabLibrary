% MSD function
function f = msd_obj(X,t,s)

f = sum((X(1)*(1-exp(-X(2)*t)) - s).^2);
