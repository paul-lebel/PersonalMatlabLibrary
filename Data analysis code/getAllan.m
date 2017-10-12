
function [RMS iTime] = getAllan(data,dt)

% This function uses randomized octave sampling of the data 

n = numel(data);
tmax = dt*n;

% nbins = round(logspace(log10(2),log10(numel(angle)),100));
nlog2 = floor(log2(n));
nbins = round( 2.^([1:nlog2]));

iTime = tmax./nbins;
RMS = zeros(numel(nbins,1));

ints = [1:n]';

for i=1:numel(nbins)
    data = circshift(data,floor(n*rand(1)));
    subs = ceil( (nbins(i)/n)*ints);
    RMS(i) = sqrt( .5*mean( diff( accumarray(subs,data)./accumarray(subs,1)).^2));
end


    
    