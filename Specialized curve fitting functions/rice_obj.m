function f = rice_obj(X,t,s)

g = (t/(X(2)^2)).*exp(-(t.^2+X(1)^2)/(2*X(2)^2)).*besseli(0,t*X(1)/(X(2)^2));

f = sum( (g-s).^2 );

return