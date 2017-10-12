
% A script to setup and run a quantitative focus lock using the position
% sensitive photodiode signal, acquired through Matlab's Data Acquisition
% Toolbox

% Date: Feb. 2nd, 2012
% Author: Paul Martin Lebel

% Uses a background listener to monitor the incoming analog voltages
% (position and sum signals) from the NI DAQ card. The listener invokes a
% callback function with limited input arguments, so a global struct is
% created in order to pass information into the callback. 

% This script defines basic focuslock parameters, creates a daq session,
% and defines a directory in which to save data.

if exist('s_lock') 
delete(s_lock);
clear s_lock
end


% The following global variables will be used to communicate with the
% listener: (declare these as global there too?)
clear lockInfo
global lockInfo   % Info struct containing gain parameters, etc.
% global PSDDataFid % File ID for PSD time, sum, and position logging
% global mclDataFid % File ID for stage motion logging: zCurrent,
% delta motion commanded, and mean of error value (mean of one loop's
% PSD signal)

global mcl_handle % Needed to share piezo stage info

% These global variables start as empty matrices without initialization
lockInfo.errSum = 0;
lockInfo.memoryLength = 20000;
lockInfo.logging = 0;
lockInfo.zCurrent = 25*ones(lockInfo.memoryLength,1);
lockInfo.zCurrent(1) = readZ(1);
lockInfo.zPSDmean = zeros(lockInfo.memoryLength,1);
lockInfo.n = 1;

% Create daq session
s_lock = daq.createSession('ni');

% Define input channels for position and sum signals. 
% This one is for the sum signal
s_lock.addAnalogInputChannel('Dev2', 'ai0', 'Voltage');
% Position signal
s_lock.addAnalogInputChannel('Dev2', 'ai1', 'Voltage');

% Define a counter input signal to record camera 'fire' signal
% ctr = s.addCounterInputChannel('Dev1','ctr0','EdgeCount');


% SET THESE PARAMETERS MANUALLY
% lockInfo.totalMovieFrames = 50000;
% lockInfo.camRate = 600; % *** Make sure Andor is properly set up in Solis
s_lock.Rate = 1000;
s_lock.IsContinuous = true;
lockInfo.daqRateActual = s_lock.Rate; % Don't set this. Just a precaution to ensure we know the actual rate.
s_lock.NotifyWhenDataAvailableExceeds = 250;
lockInfo.P = 1; % Controller proportional gain parameter
lockInfo.I = .005; % Controller integral gain parameter \
lockInfo.D = 0; % Controller differential parameter
% lockInfo.offset = (25-readZ)*1000;
% lockInfo.homeDir = uigetdir('F:\Paul_Data\Feb.2012');
lockInfo.errVec = zeros(20000,1);


% Create a background listener to do focus lock and log data
lh = s_lock.addlistener('DataAvailable', @lockOnly);

% Start lock, shoot, and log!
s_lock.startBackground();
 

