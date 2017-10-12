res = [150 80];
inds_t = ceil(res(1)*(tAccum')/(2*tWindow));
inds_a = 1+ floor( res(2)*(-min(angAccum) +angAccum')/(max(angAccum(:)) - min(angAccum(:))));

test = accumarray([inds_t inds_a],zAccum);
weights = accumarray([inds_t inds_a],1);
test = test./weights;

highData = weights > 4;
badInds = find(highData == 0);
test(badInds) = NaN;
test = test';


t_inds = linspace(-tWindow,tWindow,size(test,2));
a_inverse = (inds_a-100)/res(2)-2;
a_inds = linspace(min(angAccum),max(angAccum),size(test,1));

contourf(t_inds,a_inds,test,100,'linestyle','none')
% linspace(-.25,.25,size(test',2)),linspace(min(angAccum),max(angAccum),size(test',1))