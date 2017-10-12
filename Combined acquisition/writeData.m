function writeData(src,event)
%      plot(event.TimeStamps, event.Data)

fid1 = fopen('laserData.dat','a');
fid2 = fopen('laserTime.dat','a');
fwrite(fid1,event.Data,'double');
fwrite(fid2,event.TimeStamps,'double');

fclose(fid1);
fclose(fid2);


end



 
