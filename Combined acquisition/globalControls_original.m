function varargout = globalControls(varargin)
% STATICDIGITALCONTROLS MATLAB code for staticDigitalControls.fig
%      STATICDIGITALCONTROLS, by itself, creates a new STATICDIGITALCONTROLS or raises the existing
%      singleton*.
%
%      H = STATICDIGITALCONTROLS returns the handle to a new STATICDIGITALCONTROLS or the handle to
%      the existing singleton*.
%
%      STATICDIGITALCONTROLS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STATICDIGITALCONTROLS.M with the given input arguments.
%
%      STATICDIGITALCONTROLS('Property','Value',...) creates a new STATICDIGITALCONTROLS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before staticDigitalControls_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to staticDigitalControls_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help staticDigitalControls

% Last Modified by GUIDE v2.5 05-Feb-2014 15:35:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @staticDigitalControls_OpeningFcn, ...
                   'gui_OutputFcn',  @staticDigitalControls_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
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


% --- Executes just before staticDigitalControls is made visible.
function staticDigitalControls_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to staticDigitalControls (see VARARGIN)

% Choose default command line output for staticDigitalControls
handles.output = hObject;

global s s2 motorController force_obj rotation_obj

s = daq.createSession('ni');
s2 = daq.createSession('ni');

s.addDigitalChannel('Dev2','port0/line0','OutputOnly');
s.addDigitalChannel('Dev2','port0/line1','OutputOnly');
s.addDigitalChannel('Dev2','port0/line2','OutputOnly');
s.addDigitalChannel('Dev2','port0/line3','OutputOnly');

s2.addAnalogOutputChannel('Dev2','ao0','Voltage');
s2.Channels(1).Range = [-10 10];

handles.digiStates = zeros(1,4);
handles.IRvoltage = -.1;

[force_obj, rotation_obj, motorController] = initDaisyChain_Paul();

handles.force = 0;
handles.hPos = 0; % By default upon init.

% Digital I/O:
% Brightfield: port0/line0
% Green laser shutter: port0/line1
% Red laser shutter: port0/line2
% IR enable 

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes staticDigitalControls wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = staticDigitalControls_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in BrightFieldToggle.
function BrightFieldToggle_Callback(hObject, eventdata, handles)
% hObject    handle to BrightFieldToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global s

brightField = get(hObject,'Value');
handles.digiStates(1) = brightField;
s.outputSingleScan(handles.digiStates);
guidata(hObject, handles);

% Hint: get(hObject,'Value') returns toggle state of BrightFieldToggle


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over BrightFieldToggle.
function BrightFieldToggle_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to BrightFieldToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% 
global s s2 force_obj rotation_obj motorController
s.outputSingleScan([0 0 0 0]);
delete(s); clear s;
s2.outputSingleScan(-.1);
delete(s2); clear s2;

% close PI objects
force_obj.MOV('1',0);
rotation_obj.CloseConnection;
force_obj.CloseConnection;
motorController.CloseConnection();
motorController.Destroy;

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in GreenShutterToggle.
function GreenShutterToggle_Callback(hObject, eventdata, handles)
% hObject    handle to GreenShutterToggle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global s 

% Hint: get(hObject,'Value') returns toggle state of GreenShutterToggle
greenShutter = get(hObject,'Value');
handles.digiStates(2) = greenShutter;
s.outputSingleScan(handles.digiStates);
guidata(hObject, handles);

% --- Executes on button press in redShutter.
function redShutter_Callback(hObject, eventdata, handles)
% hObject    handle to redShutter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global s

redShutter = get(hObject,'Value');
handles.digiStates(3) = redShutter;
s.outputSingleScan(handles.digiStates);
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of redShutter


% --- Executes on button press in IRenable.
function IRenable_Callback(hObject, eventdata, handles)
% hObject    handle to IRenable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global s

IRShutter = get(hObject,'Value');
handles.digiStates(4) = IRShutter;
s.outputSingleScan(handles.digiStates);
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of IRenable


% --- Executes on slider movement.
function irPowerSlider_Callback(hObject, eventdata, handles)
% hObject    handle to irPowerSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global s2

IR_power = get(hObject,'Value');
voltage = power2voltage(IR_power);
s2.outputSingleScan(voltage);
handles.IRvoltage = voltage;
handles.IRpower = IR_power;
set(handles.irPowerText,'String',num2str(handles.IRpower,'%4.2f'));
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
global s2

IR_power = str2num(get(hObject,'String'));
voltage = power2voltage(IR_power);
s2.outputSingleScan(voltage);
handles.IRvoltage = voltage;
handles.IRpower = IR_power;
set(handles.irPowerSlider,'Value',IR_power);
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
