
function [RMS iTime] = getRMS(angle,dt)
n = numel(angle);
tmax = dt*n;

% nbins = round(logspace(log10(2),log10(numel(angle)),100));
nlog2 = floor(log2(n));
nbins = round( 2.^([1:nlog2]));

iTime = tmax./nbins;
RMS = zeros(numel(nbins,1));

ints = [1:n]';

for i=1:numel(nbins)
    angle = circshift(angle,floor(n*rand(1)));
    subs = ceil( (nbins(i)/n)*ints);
    RMS(i) = std( accumarray(subs,angle)./accumarray(subs,1));
end


    
    