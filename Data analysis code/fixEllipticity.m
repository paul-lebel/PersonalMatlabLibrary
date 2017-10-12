
% Correct for elliptical orbits by taking a series of cx,cy datapoints and
% an ellipse parameter struct (as produced by fit_ellipse) as inputs. The
% cx,cy points will be rotated by an angle equal to that of the ellipse's
% major axis from the vertical, scaled by the ratio of long axis to short
% axis, and then rotated back by the same amount.


function [xCirc, yCirc] = fixEllipticity(x,y,eStruct)

if ~iscolumn(x)
    x = x';
end
if ~iscolumn(y)
    y = y';
end

phi = eStruct.phi;

ratio = abs(eStruct.long_axis/eStruct.short_axis);

rotMat = [cos(phi) sin(phi); -sin(phi) cos(phi)];
rotMatInv = [cos(phi) -sin(phi); sin(phi) cos(phi)];
xyRot = [x y]*rotMat;

% Try correcting in one direction and test if ellipticity is reduced
xyRotTemp(:,1) = xyRot(:,1)*(eStruct.short_axis/eStruct.long_axis);
xyRotTemp(:,2) = xyRot(:,2);
eStructTemp = fit_ellipse(xyRotTemp(:,1),xyRotTemp(:,2));
ratioTemp = abs(eStructTemp.long_axis/eStructTemp.short_axis);

if ratioTemp > ratio
    xyRotFixed(:,2) = xyRot(:,2)*(eStruct.short_axis/eStruct.long_axis);
    xyRotFixed(:,1) = xyRot(:,1);
else
    xyRotFixed(:,1) = xyRot(:,1)*(eStruct.short_axis/eStruct.long_axis);
    xyRotFixed(:,2) = xyRot(:,2);
end

xyRotFixed = xyRotFixed*rotMatInv;

xCirc = xyRotFixed(:,1);
yCirc = xyRotFixed(:,2);