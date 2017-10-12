
function filteredData = zplp(data,fs,cutoff)


dt = 1/fs;
t = dt*[1:numel(data)];



d=fdesign.lowpass('N,F3db',4,1/(fs/cutoff));
% designmethods(d)
Hd = design(d,'butter');
y = filtfilt(Hd.sosMatrix,Hd.scaleValues,data);

% figure; plot(t,data,t,y); 

filteredData = y; clear y;