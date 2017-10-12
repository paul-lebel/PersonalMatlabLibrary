
% Use Aakash' scored transitions to the 0 rotation mark to plot an family
% of post-synched traces

% K: as defined in Aakash's explanation. K{i}{j}
% K{i}{1}(m) = frame number of mth transition in ith trace
% K{i}{2}(m) = integer rotation number of mth transition in ith trace
% K{i}{3}(m) = Type of transition:
%               0-->entering Omega
%               1--> on pathway alpha
%               3? --> Reversible alpha
%
% YData{i} = ith angle trace
% ZData{i} = ith z trace
% freq(i) = sampling frequency of ith trace
% jet = jet;
% fig = figure; hold all;

tWindow = 0.2;
angThres = -0.5;
% axis([-tWindow tWindow -2 3])


angAccum = [];
zAccum = [];
tAccum = [];


for i=1:numel(K)
    
    dt = 1/freq(i);
    time = dt:dt:dt*numel(Ydata{i});
    angleLP = zplp(Ydata{i},freq(i),1500);
    
    if ~isempty(K{i})
        for m = 1:numel(K{i}{1})-1
            
            if (K{i}{3}(m) == 0) && (K{i}{2}(m+1) > K{i}{2}(m)) && (mod(K{i}{2}(m),2) == 0)
                ind1 = round(K{i}{1}(m)-tWindow/dt);
                ind2 = round(K{i}{1}(m)+tWindow/dt);
                angleTemp = angleLP(ind1:ind2);
                angleTemp = angleTemp'-K{i}{2}(m+1);
                zTemp = Zdata{i}(ind1:ind2);
                tTemp = time(ind1:ind2) - time(ind1)+ 1E-6;
                if mean(angleTemp(380:end)) > angThres
                    angAccum = [angAccum angleTemp];
                    zAccum = [zAccum zTemp'];
                    tAccum = [tAccum tTemp];
                    plot(tTemp-tWindow,angleTemp,'k','linewidth',.1);
                    pause(.03); hold all;
                end
                %             colorInds = ceil(64*tTemp/(2*tWindow)); colorInds = min(colorInds,64);
                %             colorInds = max(colorInds,1);
                % colorIndZ = round(-zTemp*60/40);
                % colorIndZ = min(colorIndZ,64);
                % colorIndZ = max(colorIndZ,1);
                
                %             plot(angleTemp-K{i}{2}(m),zTemp);
                %             for j = 1:2:numel(angleTemp)
                %                 plot(tTemp(j)-tWindow,angleTemp(j)-K{i}{2}(m+1),'.','color',jet(colorIndZ(j),:));
                %                 pause(.0001);
                %             end
            end
        end
        
        if isempty(m)
            m = 1;
            ind1 = round(K{i}{1}(m)-tWindow/dt);
            ind2 = round(K{i}{1}(m)+tWindow/dt);
            angleTemp = angleLP(ind1:ind2);
            angleTemp = angleTemp'- (K{i}{2}(m)+2);
            zTemp = Zdata{i}(ind1:ind2);
            tTemp = time(ind1:ind2) - time(ind1)+ 1E-6;
            if mean(angleTemp(380:end)) > angThres
                angAccum = [angAccum angleTemp];
                zAccum = [zAccum zTemp'];
                tAccum = [tAccum tTemp];
                plot(tTemp-tWindow,angleTemp,'k','linewidth',.1);
                pause(.03); hold all;
            end
        else
            m = m+1;
            if (K{i}{3}(m-1) ~= 3) && (K{i}{3}(m) == 0)
                ind1 = round(K{i}{1}(m)-tWindow/dt);
                ind2 = round(K{i}{1}(m)+tWindow/dt);
                angleTemp = angleLP(ind1:ind2);
                angleTemp = angleTemp'- (K{i}{2}(m)+2);
                zTemp = Zdata{i}(ind1:ind2);
                tTemp = time(ind1:ind2) - time(ind1)+ 1E-6;
                if mean(angleTemp(380:end)) > angThres
                    angAccum = [angAccum angleTemp];
                    zAccum = [zAccum zTemp'];
                    tAccum = [tAccum tTemp];
                    plot(tTemp-tWindow,angleTemp,'k','linewidth',.1);
                    pause(.03); hold all;
                end
            end
        end
    end
end
