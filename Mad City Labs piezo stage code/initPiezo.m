

mclDir = ['C:\Users\Zev Bryant\Documents\MATLAB\Paul\Mad City Labs piezo stage code\']; 
hFile = [mclDir 'Madlib.h'];
dllFile = [mclDir 'Madlib.dll'];
loadlibrary(dllFile, hFile);
mcl_handle = calllib('Madlib','MCL_InitHandleOrGetExisting');

piezoRange(1) = calllib('Madlib','MCL_GetCalibration',1,mcl_handle); 
piezoRange(2) = calllib('Madlib','MCL_GetCalibration',2,mcl_handle); 
piezoRange(3) = calllib('Madlib','MCL_GetCalibration',3,mcl_handle); 

centerPiezo(mcl_handle,piezoRange);