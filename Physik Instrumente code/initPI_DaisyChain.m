% Code to initialize both PI motors in the daisy chain configuration.
% magnetHeight_obj: 'PI C-863 Mercury SN 0115500121'
% magnetAngle_obj: 'PI C-863 Mercury SN 0105500299'
% Motor 1: M-126.PD1 linear translation stage
% Motor 2: C-150.PD rotary motor
% This code assumes magnetHeight_obj is the 'master' controller and magnetAngle_obj
% is the slave

function [magnetHeight_obj, magnetAngle_obj, Controller] = initPI_DaisyChain()

stagename{1} = 'M-126.PD1';
stagename{2}= 'C-150.PD';

if(~exist('Controller'))
    Controller = PI_GCS_Controller();
end;

if(~Controller.IsConnected)
    % connect using the serial port
    disp('Enumerating USB devices')
    
    devices = Controller.EnumerateUSB('')
    Controller = Controller.OpenUSBDaisyChain(devices);
   
    % Vertical motor
    magnetHeight_obj=Controller.ConnectDaisyChainDevice(1);
    
    % Rotary motor
    magnetAngle_obj=Controller.ConnectDaisyChainDevice(2);
    
    % Query identification
    magnetHeight_obj.qIDN()
    magnetAngle_obj.qIDN()
    
end

availableaxes1 = magnetHeight_obj.qSAI_ALL();
availableaxes2 = magnetAngle_obj.qSAI_ALL();

if(isempty(availableaxes1)|| isempty(availableaxes2))
	return;
end

axisname1 = availableaxes1;
axisname2 = availableaxes2;

% Connect the stages, displaying output
magnetHeight_obj.CST(axisname1,stagename{1});
magnetHeight_obj.qCST(axisname1)
magnetAngle_obj.CST(axisname2,stagename{2});
magnetAngle_obj.qCST(axisname2)

% Set absolute position of rotary motor:
ready = input('Adjust rotary motor to zero position, then hit enter');
clear ready;

% Turn servo modes on
magnetHeight_obj.SVO(axisname1,1);
magnetAngle_obj.SVO(axisname2,1);

% Set the rotary motor to zero
magnetAngle_obj.RON(axisname2,0);
magnetAngle_obj.POS(axisname2,0);

% Reference the vertical stage 
disp('Referencing the vertical stage');
% magnetHeight_obj.FNL(axisname1)
magnetHeight_obj.FRF(axisname1)

bReferencing = 1;
% wait for Referencing to finish
while(bReferencing)
	pause(0.1);
	bReferencing = (magnetHeight_obj.qFRF(axisname1)==0);
end
% Determine min and max range of motion for vertical motor
dMin1 = magnetHeight_obj.qTMN(axisname1);
dMax1 = magnetHeight_obj.qTMX(axisname1);

magnetAngle_obj.VEL('1',180);
magnetHeight_obj.VEL('1',5);

magnetHeight_obj.MOV('1',0);



