

% Objective function for the fitting script 'rotorFit.m'

function f = rotor_obj(X,t,s)

% cx and cy must be column vectors:
if ~iscolumn(t)
    t = t';
end
if ~iscolumn(s)
    s = s';
end

N = hist3([s t],[100 100]);
N = N/mean(N(:));
P = rotorSmear_s(X,[100 100]);
P = P/mean(P(:));


f = sum( (N(:)-P(:)).^2);

return
