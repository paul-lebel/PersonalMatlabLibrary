function dataCorr = subPoly(ydata,order)

xdata = [1:numel(ydata)]';
if ~iscolumn(ydata)
    ydata = ydata';
end

[p s mu] = polyfit(xdata,ydata(:),order);


dataCorr = ydata - polyval(p,(xdata-mu(1))./mu(2));

end