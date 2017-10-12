% Code to initialize both PI motors in the daisy chain configuration.
% magH_obj: 'PI C-863 Mercury SN 0115500121'
% magAng_obj: 'PI C-863 Mercury SN 0105500299'
% Motor 1: M-126.PD1 linear translation stage
% Motor 2: C-150.PD rotary motor
% This code assumes magH_obj is the 'master' controller and magAng_obj
% is the slave
function [magH_obj, magAng_obj, Controller] = initDaisyChain_Paul()

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
    magH_obj=Controller.ConnectDaisyChainDevice(1);
    
    % Rotary motor
    magAng_obj=Controller.ConnectDaisyChainDevice(2);
    
    % Query identification
    magH_obj.qIDN()
    magAng_obj.qIDN()
    
end

availableaxes1 = magH_obj.qSAI_ALL();
availableaxes2 = magAng_obj.qSAI_ALL();

if(isempty(availableaxes1)|| isempty(availableaxes2))
	return;
end

axisname1 = availableaxes1;
axisname2 = availableaxes2;

% Connect the stages, displaying output
magH_obj.CST(axisname1,stagename{1});
magH_obj.qCST(axisname1)
magAng_obj.CST(axisname2,stagename{2});
magAng_obj.qCST(axisname2)

% Set absolute position of rotary motor:
ready = input('Adjust rotary motor to zero position, then hit enter');
clear ready;

% Turn servo modes on
magH_obj.SVO(axisname1,1);
magAng_obj.SVO(axisname2,1);

% Set the rotary motor to zero
magAng_obj.RON(axisname2,0);
magAng_obj.POS(axisname2,0);

% Reference the vertical stage 
disp('Referencing the vertical stage');
% magH_obj.FNL(axisname1)
magH_obj.FRF(axisname1)

bReferencing = 1;
% wait for Referencing to finish
while(bReferencing)
	pause(0.1);
	bReferencing = (magH_obj.qFRF(axisname1)==0);
end
% Determine min and max range of motion for vertical motor
dMin1 = magH_obj.qTMN(axisname1);
dMax1 = magH_obj.qTMX(axisname1);

magAng_obj.VEL('1',180);
magH_obj.VEL('1',5);
magH_obj.MOV('1',0);




