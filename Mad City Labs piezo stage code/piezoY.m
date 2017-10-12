
% Function which sets the y position of the mad city labs piezo stage 

% Author: Paul Lebel
% Date: Jan 4th, 2012

% Input arguments: 
% mcl_handle = an integer which specifies the MCL library which stage to
% control.
% yPos = position to set the stage to, in microns. Valid range for PDQ
% stage is 0-75.

% Output
% flag: success = true, failure = false

function flag = piezoY(mcl_handle,yPos)

temp = calllib('Madlib','MCL_SingleWriteN',yPos,2,mcl_handle); 

if temp==0
    flag = true;
else
    flag = false;
end


end