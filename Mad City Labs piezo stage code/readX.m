% Simple function to read the x position of the piezo stage

% Author: Paul Lebel
% Date: Jan. 18th, 2012

% Input arguments:
% mcl_handle = an integer which specifies the MCL library which stage to
% control.

% Output arguments:
% xpos = current position of the stage, in um


function xpos = readX(mcl_handle)

if nargin<1
    mcl_handle = 1;
end

% Average over 100 measurements
temp = zeros(1,100);

for i=1:100
temp(i) = calllib('Madlib','MCL_SingleReadN',1,mcl_handle);
end

xpos = mean(temp);