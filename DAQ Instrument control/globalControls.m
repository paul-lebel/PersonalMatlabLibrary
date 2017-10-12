function varargout = globalControls(varargin)
%GLOBALCONTROLS M-file for globalControls.fig
%      GLOBALCONTROLS, by itself, creates a new GLOBALCONTROLS or raises the existing
%      singleton*.
%
%      H = GLOBALCONTROLS returns the handle to a new GLOBALCONTROLS or the handle to
%      the existing singleton*.
%
%      GLOBALCONTROLS('Property','Value',...) creates a new GLOBALCONTROLS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to globalControls_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      GLOBALCONTROLS('CALLBACK') and GLOBALCONTROLS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in GLOBALCONTROLS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help globalControls

% Last Modified by GUIDE v2.5 17-May-2014 16:44:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @globalControls_OpeningFcn, ...
                   'gui_OutputFcn',  @globalControls_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before globalControls is made visible.
function globalControls_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)


% These variables are global because they are controlled from other
% functions. It's almost certainly possible to do this entirely by passing
% function arguments, but this was easier to implement. 
global sdaq1 sdaq2 motorController force_obj rotation_obj 
global present_daq2Vals digiStates

sdaq1 = daq.createSession('ni');  % Initialize digital controls daq session 
sdaq2 = daq.createSession('ni');  % Initialize analog controls daq session
sdaq1.addDigitalChannel('Dev2','port0/line1','OutputOnly');    % Port 0 / line 1  == Green shutter
sdaq1.addDigitalChannel('Dev2','port0/line2','OutputOnly');    % Port 0 / line 2  == Red shutter 
sdaq1.addDigitalChannel('Dev2','port0/line3','OutputOnly');    % Port 0 / line 3  == IR enable
sdaq2.addAnalogOutputChannel('Dev2','ao0','Voltage');          % AI0 == IR modulation
sdaq2.addAnalogOutputChannel('Dev2','ao1','Voltage');          % AI1 == Brightfield modulation
sdaq2.Channels(1).Range = [-10 10];
sdaq2.Channels(2).Range = [-10 10];

% Initialize starting output values for the two daq sessions (all off)
handles.digiStates = zeros(1,3);
handles.IRvoltage = -.1; % -0.1 completely shuts off the laser (0 does not!)
handles.BFvoltage = -.1;
digiStates = handles.digiStates;
present_daq2Vals = [handles.IRvoltage handles.BFvoltage];

% Initialize the PI motors
[force_obj, rotation_obj, motorController] = initDaisyChain_Paul;

% These variables are for bookeeping, just like the IRvoltage and BFvoltage
handles.force = 0;
handles.hPos = 0; % By default upon init.
handles.magnetAngle = 0;
handles.magnetSpeed = 10;

% Choose default command line output for globalControls
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes globalControls wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = globalControls_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in GreenShutterToggle.
function GreenShutterToggle_Callback(hObject, eventdata, handles)
% hObject    handle to GreenShutterToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global  sdaq1 digiStates
greenShutter = get(hObject,'Value');
handles.digiStates(1) = greenShutter;
sdaq1.outputSingleScan(handles.digiStates);
digiStates = handles.digiStates;
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of GreenShutterToggle


% --- Executes on button press in redShutter.
function redShutter_Callback(hObject, eventdata, handles)
% hObject    handle to redShutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global sdaq1 digiStates
redShutter = get(hObject,'Value');
handles.digiStates(2) = redShutter;
sdaq1.outputSingleScan(handles.digiStates);
digiStates = handles.digiStates;
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of redShutter


% --- Executes on button press in IRenable.
function IRenable_Callback(hObject, eventdata, handles)
% hObject    handle to IRenable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global sdaq1 digiStates

IRShutter = get(hObject,'Value');
handles.digiStates(3) = IRShutter;
sdaq1.outputSingleScan(handles.digiStates);
digiStates = handles.digiStates;

guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of IRenable


% --- Executes on slider movement.
function irPowerSlider_Callback(hObject, eventdata, handles)
% hObject    handle to irPowerSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global sdaq2 present_daq2Vals

IR_power = get(hObject,'Value');
voltage = power2voltage(IR_power);
sdaq2.outputSingleScan([voltage handles.BFvoltage]);
handles.IRvoltage = voltage;
handles.IRpower = IR_power;
set(handles.irPowerText,'String',num2str(handles.IRpower,'%4.2f'));
present_daq2Vals = [voltage handles.BFvoltage];
guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function irPowerSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to irPowerSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function irPowerText_Callback(hObject, eventdata, handles)
% hObject    handle to irPowerText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global sdaq2 present_daq2Vals

IR_power = str2num(get(hObject,'String'));
voltage = power2voltage(IR_power);
sdaq2.outputSingleScan([voltage handles.BFvoltage]);
handles.IRvoltage = voltage;
handles.IRpower = IR_power;
set(handles.irPowerSlider,'Value',IR_power);
present_daq2Vals = [voltage handles.BFvoltage];
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of irPowerText as text
%        str2double(get(hObject,'String')) returns contents of irPowerText as a double


% --- Executes during object creation, after setting all properties.
function irPowerText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to irPowerText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function forceControlSlider_Callback(hObject, eventdata, handles)
% hObject    handle to forceControlSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global force_obj
force = get(hObject,'Value');
hPos = Ftoh_halfInch(force);
handles.force = force;
handles.hPos = hPos;
setForce(force_obj,force);
currentMag_h = force_obj.qPOS('1');
set(handles.text7,'String',num2str(currentMag_h));
set(handles.forceControlText,'String',num2str(force,'%4.2f'));

guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function forceControlSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to forceControlSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function forceControlText_Callback(hObject, eventdata, handles)
% hObject    handle to forceControlText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global force_obj

force = str2num(get(hObject,'String'));
hPos = Ftoh_halfInch(force);
handles.force = force;
handles.hPos = hPos;
set(handles.forceControlSlider,'Value',force);
setForce(force_obj,force);
currentMag_h = force_obj.qPOS('1');
set(handles.text7,'String',num2str(currentMag_h));
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of forceControlText as text
%        str2double(get(hObject,'String')) returns contents of forceControlText as a double


% --- Executes during object creation, after setting all properties.
function forceControlText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to forceControlText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function magnetRotation_Callback(hObject, eventdata, handles)
% hObject    handle to magnetRotation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global rotation_obj

magnetAngle = str2num(get(hObject,'String'));
handles.magnetAngle = magnetAngle;
rotation_obj.MOV('1',magnetAngle);

guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of magnetRotation as text
%        str2double(get(hObject,'String')) returns contents of magnetRotation as a double


% --- Executes during object creation, after setting all properties.
function magnetRotation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to magnetRotation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global sdaq1 sdaq2 force_obj rotation_obj motorController
sdaq1.outputSingleScan([0 0 0]);
sdaq2.outputSingleScan([-.1 -.1]);
delete(sdaq1); 
delete(sdaq2);
clear -global sdaq1 sdaq2

% handles.magnetAngle_obj.CloseConnection;
%         handles.magnetHeight_obj.CloseConnection;
%         handles.Controller.CloseDaisyChain();
%         handles.Controller.Destroy;

% close PI objects
force_obj.MOV('1',0);
force_obj.CloseConnection;
rotation_obj.CloseConnection;
motorController.CloseDaisyChain();
motorController.Destroy;
clear -global motorController force_obj rotation_obj

% 
% clearvars -global force_obj rotation_obj motorController s s2
% Hint: delete(hObject) closes the figure
delete(hObject);



function magSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to magSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global rotation_obj

magnetSpeed = str2num(get(hObject,'String'));
handles.magnetSpeed = magnetSpeed;
rotation_obj.VEL('1',magnetSpeed);

guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of magSpeed as text
%        str2double(get(hObject,'String')) returns contents of magSpeed as a double


% --- Executes during object creation, after setting all properties.
function magSpeed_CreateFcn(hObject, eventdata, handles)
% hObject    handle to magSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function BFpower_Callback(hObject, eventdata, handles)
% hObject    handle to BFpower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global sdaq2

handles.BFvoltage = get(hObject,'Value');
% voltage = power2voltage(BF_power);
sdaq2.outputSingleScan([handles.IRvoltage handles.BFvoltage]);
set(handles.BrightControlText,'String',num2str(handles.BFvoltage,'%4.2f'));
guidata(hObject, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function BFpower_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BFpower (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function BrightControlText_Callback(hObject, eventdata, handles)
% hObject    handle to BrightControlText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global sdaq2

handles.BFvoltage = str2num(get(hObject,'String'));
sdaq2.outputSingleScan([handles.IRvoltage handles.BFvoltage]);
set(handles.BFpower,'Value',handles.BFvoltage);
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of BrightControlText as text
%        str2double(get(hObject,'String')) returns contents of BrightControlText as a double


% --- Executes during object creation, after setting all properties.
function BrightControlText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BrightControlText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
