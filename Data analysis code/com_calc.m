% awesome center of mass calculation

function [cx cy I ellip] = com_calc(vid)

% if size(size(vid)) ~= 3
%     error('Incorrect dims')
% end

Vsize = size(vid,1);
Hsize = size(vid,2);
numFrames = size(vid,3);

xvec = zeros(1,Hsize,numFrames);
yvec = zeros(Vsize,1,numFrames);

I = shiftdim(sum(sum(vid,1),2));

projx = sum(vid,2);
projy = sum(vid,1);

ellipx = std(shiftdim(projy))';
ellipy = shiftdim(std(projx,1));


for i=1:numFrames
xvec(:,:,i) = 1:Hsize;
yvec(:,:,i) = 1:Vsize';
end

cx = shiftdim(sum(projy.*xvec,2))./I;
cy = shiftdim(sum(projx.*yvec,1))./I;
ellip = (ellipy-ellipx)./(ellipy+ellipx);


