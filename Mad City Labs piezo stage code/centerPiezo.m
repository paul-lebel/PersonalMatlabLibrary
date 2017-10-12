
% Center the piezo's 3 axes

function centerPiezo(mcl_handle,piezoRange)
piezoX(mcl_handle,piezoRange(1)/2);
piezoY(mcl_handle,piezoRange(2)/2);
piezoZ(mcl_handle,piezoRange(3)/2);
end