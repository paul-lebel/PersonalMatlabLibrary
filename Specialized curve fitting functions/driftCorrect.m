

function [cx_dc, cy_dc, ro] = driftCorrect(cx,cy,dt)


% Fit circles every chunk of data and subtract centre (method 3)
chunksize = round(1/dt); % Frames; set to be number of frames in 3 seconds
numcorrs = floor(length(cx)/chunksize);

cx_dc = zeros(size(cx)); cy_dc = cx_dc;

for i = 1:numcorrs
    chunk = (1+(i-1)*chunksize):(i*chunksize);
    %         [xtemp ytemp ro] = circleFit_dc(cx(chunk),cy(chunk));
    ellipStats = fit_ellipse(cx(chunk),cy(chunk));
    if ~isempty(ellipStats.status)
        cx_dc(chunk) = cx(chunk);
        cy_dc(chunk) = cy(chunk);
    else
        xtemp = ellipStats.X0_in;
        ytemp = ellipStats.Y0_in;
        cx_dc(chunk) = cx(chunk) - xtemp;
        cy_dc(chunk) = cy(chunk) - ytemp;
        %             disp(i/numcorrs);
    end
end

% Fix remainder
chunk = (numel(cx)-chunksize+1):numel(cx);
ellipStats = fit_ellipse(cx(chunk),cy(chunk));
xtemp = ellipStats.X0_in;
ytemp = ellipStats.Y0_in;
cx_dc(chunk) = cx(chunk) - xtemp;
cy_dc(chunk) = cy(chunk) - ytemp;

% Final correction of the whole movie
ellipStats = fit_ellipse(cx_dc,cy_dc);
 if ~isempty(ellipStats.status)
        cx_dc(chunk) = cx(chunk);
        cy_dc(chunk) = cy(chunk);
        ro = mean(sqrt(cx.^2 + cy.^2));
 else
    xtemp = ellipStats.X0_in;
    ytemp = ellipStats.Y0_in;
    ro = ellipStats.long_axis;
    cx_dc = cx_dc-xtemp;
    cy_dc = cy_dc-ytemp;
 end
