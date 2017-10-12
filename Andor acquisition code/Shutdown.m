 

% Execute these commands to shut down the Andor camera and
% the piezo stage

% Set the temperature to room temp. and shut down the camera
SetTemperature(20);
AndorShutdown;

% Set the positions of all three axes to zero
calllib('Madlib','MCL_SingleWriteN',0,1,mcl_handle);
calllib('Madlib','MCL_SingleWriteN',0,2,mcl_handle); 
calllib('Madlib','MCL_SingleWriteN',0,3,mcl_handle);
    
% Release the handle to the stage    
calllib('Madlib','MCL_ReleaseAllHandles');