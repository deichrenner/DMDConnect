function varargout = DMDConnect(varargin)
% DMDCONNECT MATLAB code for DMDConnect.fig
%      DMDCONNECT, by itself, creates a new DMDCONNECT or raises the existing
%      singleton*.
%
%      H = DMDCONNECT returns the handle to a new DMDCONNECT or the handle to
%      the existing singleton*.
%
%      DMDCONNECT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DMDCONNECT.M with the given input arguments.
%
%      DMDCONNECT('Property','Value',...) creates a new DMDCONNECT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DMDConnect_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DMDConnect_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DMDConnect

% Last Modified by GUIDE v2.5 04-Mar-2016 23:14:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DMDConnect_OpeningFcn, ...
                   'gui_OutputFcn',  @DMDConnect_OutputFcn, ...
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


% --- Executes just before DMDConnect is made visible.
function DMDConnect_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DMDConnect (see VARARGIN)

% define default values
handles.Host = '134.100.104.14';
handles.Port = 8093;

% Choose default command line output for DMDConnect
handles.output = hObject;

jCalCode = com.mathworks.widgets.SyntaxTextPane;
codeType = jCalCode.M_MIME_TYPE;  % ='text/m-MATLAB'
jCalCode.setContentType(codeType)
str = ['dmdsz = [1080, 1920]; % define dmd size\n' ...
    '[xx, yy] = meshgrid(-dmdsz(2)/2:dmdsz(2)/2-1,-dmdsz(1)/2:dmdsz(1)/2-1);\n' ...
    'r = sqrt(xx.^2 + yy.^2); % generate radial vector\n' ...
    'I = zeros(dmdsz); % define image to be displayed\n' ...
    'I(r>200) = 1; % set ring\n' ...
    'imagesc(I); % show preview'];
str = sprintf(strrep(str,'%','%%'));
jCalCode.setText(str);
jScrollPane = com.mathworks.mwswing.MJScrollPane(jCalCode);
javacomponent(jScrollPane,[260,220,650,340],gcf);
jCalCode.setCaretPosition(1);

handles.jCalCode = jCalCode;

set(handles.tgbStop, 'Enable', 'off');
set(handles.tgbPause, 'Enable', 'off');

handles.d = DMD('debug', 3);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DMDConnect wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DMDConnect_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pbGenBMP.
function pbGenBMP_Callback(hObject, eventdata, handles)
% hObject    handle to pbGenBMP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set the source image axis as the current axis
axes(handles.axImg);
% get the command string from the calibration code text window
cmd = get(handles.jCalCode, 'Text');
% save command as tmp.m file and mlint
fId = fopen([tempdir 'tmp.m'] ,'w');
fprintf(fId,'%s\n', cmd);
fclose(fId);
msg = checkcode([tempdir 'tmp.m'],'-string');
delete([tempdir 'tmp.m']);
% if error in code show warning, else execute the command
if msg
    warndlg({'The supplied code features an error:', msg});
else
    % evaluate the code
    eval(cmd);
    xlim([1 1920]);
    ylim([1 1080]);
    set(gca,'XTick',[]) % Remove the ticks in the x axis!
    set(gca,'YTick',[]) % Remove the ticks in the y axis
    set(gca,'Units','Normalized');
    handles.BMP = I;
    guidata(hObject, handles);
end

% --- Executes on button press in pbPerfCal.
function pbPerfCal_Callback(hObject, eventdata, handles)
% hObject    handle to pbPerfCal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles, 'calRes') && isfield(handles, 'calSrc')
    moving = double(handles.calRes); % calibration image
    fixed = double(handles.calSrc); % reference image
    
    % start referencing tool
    [movingPoints,fixedPoints] = cpselect(moving/max(moving(:)), ...
        fixed-min(fixed(:)), 'Wait', true);
    tform = fitgeotrans(movingPoints, fixedPoints, 'NonreflectiveSimilarity');
    save('tform.mat', 'tform');
    % calculate projection of calibration image to reference image and display
    cal = imwarp(moving,tform,'OutputView',imref2d(size(fixed)));
    axes(handles.axCal);
    imagesc(cal);
    set(gca,'XTick',[]) % Remove the ticks in the x axis
    set(gca,'YTick',[]) % Remove the ticks in the y axis
    handles.Cal = tform;
    guidata(hObject, handles); % update handles struct
else
    warndlg('You have to specify a calibration image and the resulting picture first');
end

% --- Executes on button press in pbSelBMP.
function pbSelBMP_Callback(hObject, eventdata, handles)
% hObject    handle to pbSelBMP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[img, dir] = uigetfile('*.bmp', 'Select Image...');
imgpath = [dir filesep img];
if exist(imgpath, 'file')
    I = rgb2gray(imread(imgpath));
    axes(handles.axImg);
    imagesc(I);
    set(gca,'XTick',[]) % Remove the ticks in the x axis
    set(gca,'YTick',[]) % Remove the ticks in the y axis
    handles.BMP = I; % make the image known to the handles struct
    guidata(hObject, handles); % update handles struct
end


% --- Executes on button press in tgbSync.
function tgbSync_Callback(hObject, eventdata, handles)
% hObject    handle to tgbSync (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tgbSync



function edDelayT_Callback(hObject, eventdata, handles)
% hObject    handle to edDelayT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edDelayT as text
%        str2double(get(hObject,'String')) returns contents of edDelayT as a double


% --- Executes during object creation, after setting all properties.
function edDelayT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edDelayT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edOnT_Callback(hObject, eventdata, handles)
% hObject    handle to edOnT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edOnT as text
%        str2double(get(hObject,'String')) returns contents of edOnT as a double


% --- Executes during object creation, after setting all properties.
function edOnT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edOnT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in tgbPlay.
function tgbPlay_Callback(hObject, eventdata, handles)
% hObject    handle to tgbPlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tgbPlay
if get(hObject, 'Value')
    set(handles.tgbStop, 'Enable', 'on');
    set(handles.tgbPause, 'Enable', 'on');
    set(handles.tgbPlay, 'Enable', 'off');
    set(handles.tgbPause, 'Value', 0);
    set(handles.tgbStop, 'Value', 0);
    d = handles.d;
    d.display(handles.BMP);
end

% --- Executes on button press in tgbPause.
function tgbPause_Callback(hObject, eventdata, handles)
% hObject    handle to tgbPause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tgbPause
if get(hObject, 'Value')
    set(handles.tgbStop, 'Enable', 'on');
    set(handles.tgbPause, 'Enable', 'off');
    set(handles.tgbPlay, 'Enable', 'on');
    set(handles.tgbPlay, 'Value', 0);
    d = handles.d;
    d.patternControl(1);
end

% --- Executes on button press in tgbStop.
function tgbStop_Callback(hObject, eventdata, handles)
% hObject    handle to tgbStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tgbStop
if get(hObject, 'Value')
    set(handles.tgbStop, 'Enable', 'off');
    set(handles.tgbPause, 'Enable', 'off');
    set(handles.tgbPlay, 'Enable', 'on');
    set(handles.tgbPlay, 'Value', 0);
    set(handles.tgbStop, 'Value', 0);
    set(handles.tgbPause, 'Value', 0);
    d = handles.d;
    d.patternControl(0);
end

% --- Executes on button press in pbFlatF.
function pbFlatF_Callback(hObject, eventdata, handles)
% hObject    handle to pbFlatF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%Get the Experiment Control status. Might throw an exception.
function reply = queryECStatus(handles)
%@return:   The reply from Experiment Control
%Queries Experiment Control's status. Might throw an exception when
%Experiment Control is not running, so the use of a
%try/catch-construct is highly recommended when using this method.

%I dont check for an error here, because giving the error to the
%caller function enables a better handling for this event.

import java.net.*;
import java.io.*;
%Establish connection
socket = Socket(handles.Host, handles.Port);
out = socket.getOutputStream;
in = socket.getInputStream;
out.write(int8(['GETSTATUS' 10]));
%Waiting for messages from Server
while ~(in.available)
end
n = in.available;
%Buffer size = 300 characters
reply = zeros(1,300);
for i = 1:n
    reply(i) = in.read();
end
close(socket);
