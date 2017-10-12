function lockOnly(src,event)

global lockInfo
global mcl_handle
% global PSDDataFid
% global mclDataFid

lockInfo.n = lockInfo.n+1;

% PSD_to_nm = 5270;  % Widefield 532nm measured 09/15/2013 
% PSD_to_nm = 4573; % Widefield 845 nm, measured 09/18/2013
% PSD_to_nm = 1761; % IR path, calibrated 09/16/2013
% PSD_to_nm = 2229;  % New IR path, November 2013
PSD_to_nm = 1834;   % Shriram, calibration October 20th Paul Lebel

offset = 0; % in nm
offset = offset/PSD_to_nm;

darkSignalXsum = -5.9E-5; %On green path, measured 09/15/2013
% darkSignalXsum = .0008; % On IR path

ynorm = event.Data(:,2)./(event.Data(:,1)-darkSignalXsum);
meanY = mean(ynorm)-offset;

% Update the error vector if there is enough laser power. If there is not
% enough power, keep the integral term constant
lockInfo.errVec = circshift(lockInfo.errVec,1);
lockInfo.zCurrent = circshift(lockInfo.zCurrent,1);


% Check if the sum sigal is large enough (is the laser hitting the
% detector?) If not, hold the previous value of the error.
if abs(mean(event.Data(:,1))) > .01
    lockInfo.errVec(1) = meanY;
else
    lockInfo.errVec(1) = lockInfo.errVec(2);
end

 % Compute the sum and difference terms
errSum = sum(lockInfo.errVec(1:min(lockInfo.n,20000)));
errDif = lockInfo.errVec(1)-lockInfo.errVec(2);

% Compute measured position from PSD sensor
zPSD = PSD_to_nm*ynorm;
lockInfo.zPSDmean(lockInfo.n) = mean(zPSD);

delta = (lockInfo.P*meanY + lockInfo.I*errSum + lockInfo.D*errDif);
delta = min(delta,.1);
delta = max(delta,-.1);

% plot(event.Data(:,1));
% ylim([-5 2])
% text(1,-0.1,num2str(mean(zPSD)));

lockInfo.zCurrent(1) = lockInfo.zCurrent(2)+delta;
sumSig = abs(mean(event.Data(:,1)));

if abs(sumSig) > .02
calllib('Madlib','MCL_SingleWriteN',lockInfo.zCurrent(1),3,mcl_handle); 
end


if lockInfo.logging ==true
% Write the PSD data to file. Append new data each time callback is entered
% Time / Sum / Pos / Count
% fprintf(PSDDataFid,'%12.8f %12.8f %12.8f %12.8f \n', [event.TimeStamps'; event.Data(:,1)'; event.Data(:,2)'; event.Data(:,3)']);

% Write piezo stage info to file. Append new data each time callback is
% entered. 
% Piezo position / correction applied / mean error signal in nm
% fprintf(mclDataFid,'%12.8f %12.8f %12.8f \n', [lockInfo.zCurrent(1); delta; lockInfo.zPSDmean(lockInfo.n)]);
end

end




