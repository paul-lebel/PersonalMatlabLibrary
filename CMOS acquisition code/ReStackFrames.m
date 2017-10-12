% Convert long image to stack of images
function gstack = ReStackFrames(data,framedims,imgsPerFrame,numBigFrames)

h = framedims(1);
w = framedims(2);
gstack = zeros(h,w,imgsPerFrame*numBigFrames,class(data));

data = squeeze(data);

for j=1:numBigFrames
for i=1:imgsPerFrame
    ind1 = h*(i-1) + 1;
    ind2 = h*i;
    gstack(:,:,imgsPerFrame*(j-1)+i) = data(ind1:ind2,:,j);
end
end


