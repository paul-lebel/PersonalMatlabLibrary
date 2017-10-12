
function plotanglezf(time,angle,z,f,D,inds)

if nargin<6
    inds = 1:length(time);
end


% figure;
subplot(3,1,1);
plot(time(inds),angle(inds),'o','markersize',2);
ylabel('Cumulative rotations','fontsize',13);
grid on; hold all;

subplot(3,1,2);
plot(time(inds),z(inds),'o','markersize',2);
ylabel('Z [nm] ','fontsize',13);
grid on; hold all;


subplot(3,1,3);
plot(time(inds),D(inds),'go-','markersize',2); hold all;
plot(time(inds),f(inds),'ro-','markersize',2); 

xlabel('Time [s]','fontsize',13);
ylabel('Count rate [Hz]','fontsize',13);
hold all;