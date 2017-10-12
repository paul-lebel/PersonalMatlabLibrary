
% Function which sets the z position of the mad citz labs piezo stage 

% Author: Paul Lebel
% Date: Jan 4th, 2012

% Input arguments: 
% mcl_handle = an integer which specifies the MCL library which stage to
% control.
% zPos = position to set the stage to, in microns. Valid range for PDQ
% stage is 0-75.

% Output
% flag: success = true, failure = false

function flag = piezoZ(mcl_handle,zPos)

temp = calllib('Madlib','MCL_SingleWriteN',zPos,3,mcl_handle); 

if temp==0
    flag = true;
else
    flag = false;
end


end