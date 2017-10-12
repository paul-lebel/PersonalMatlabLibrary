
% shut down the piezo stage


zeroPiezo(mcl_handle);

calllib('Madlib','MCL_ReleaseAllHandles');
unloadlibrary('Madlib');

disp('If stage axis positions are ~zero, you may now power down the driver')