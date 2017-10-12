function plotTestData(src,event)

global digiFig;
% 
set(0,'CurrentFigure',digiFig);
plot(event.TimeStamps,event.Data(:,2));
hold all;
plot(event.TimeStamps,event.Data(:,1));

% xlim([event.TimeStamps

end