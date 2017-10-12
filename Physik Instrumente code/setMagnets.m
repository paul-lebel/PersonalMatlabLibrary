

function setMagnets(Controller,pos)

if numel(pos==1)
    tempstr = Controller.qCST;
    tempstr = tempstr(1:end-1);
    
    if (strcmp(tempstr, '1=M-126.PD1'))
        if pos> 23.2
            disp('Max magnet position is 23.2mm!');
            pos = 23.2;
        end
        
        if pos < 0
            disp('Cannot move to less than 0!');
            pos = 0;
        end
    end
    
    Controller.MOV('1',pos);
else
    error('Force is not a scalar');
end


end