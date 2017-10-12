

function setForce(Controller,Force)

if numel(Force==1)
    pos = Ftoh_halfInch(Force);
    pos = min(pos,15.50);
    pos = max(pos,0);
    
    if pos < 15.50 % Oct 21st 2014 collision point 15.56 mm  // %24.55 %23.2
        Controller.MOV('1',pos);
    end
    if Force == 0
        Controller.MOV('1',0);
    end
    
else
    error('Force is not a scalar');
end


end