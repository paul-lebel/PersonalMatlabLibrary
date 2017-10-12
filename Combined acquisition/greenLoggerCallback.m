function greenLoggerCallback(src,event)

global sensorData 

% plot(event.TimeStamps,event.Data(:,2));
% hold all;
% plot(event.TimeStamps,event.Data(:,1));

% sensorData.bigInd = sensorData.bigInd + numel(event.Data(:,2));
% sensorData.litInd = sensorData.bigInd - numel(event.Data(:,2))+1;
% sensorData.data(sensorData.litInd:sensorData.bigInd) = event.Data(:,1);

% fprintf(sensorFid,'%12.8f %12.8f \n', [event.TimeStamps'; event.Data(:,1)']);

end