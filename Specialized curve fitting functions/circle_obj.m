function f = circle_obj(X,t,s)

% f is the sum of square distances of points from the circle. We minimize f
% by adjusting the circle's center and radius

f = shiftdim(nansum( ((t-X(1)).^2+(s-X(2)).^2-X(3)^2).^2));

return

