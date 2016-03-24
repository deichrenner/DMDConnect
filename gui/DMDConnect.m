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

% insert coding window with example code
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
javacomponent(jScrollPane,[185,230,650,450],gcf);
jCalCode.setCaretPosition(1);
handles.jCalCode = jCalCode;

% do not show any java related warning
warning('off', 'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');

% initialize the pause/stop buttons
set(handles.tgbStop, 'Enable', 'off');
set(handles.tgbPause, 'Enable', 'off');

% connect to the dmd
d = DMD('debug', 0);
% put the dmd to sleep
d.sleep;
% make dmd object known to the handles struct
handles.d = d;

% mark the sync flag as not being in sync
handles.inSync = 0;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DMDConnect wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- This function sets the actual status of the DMD in the status bar
function setDMDstatus(handles)
% status     cell strin containing the dmd status information
% handles    structure with handles and user data (see GUIDATA)
% insert status bar in the bottom region of the window

% read status and show
status = handles.d.status;
statusbar(['Status: ' status{:}]); %#ok<*MSNU>


% --- Outputs from this function are returned to the command line.
function varargout = DMDConnect_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% make the statusbar visible and show status of the dmd
d = handles.d;
status = d.status;
old_pos = get(gcf,'Position');
set(gcf,'Position',1.05.*old_pos);
set(gcf,'Position',old_pos);
stat = statusbar(['Status: ' status{:}]); %#ok<*MSNU>
set(stat.CornerGrip, 'visible', false); %#ok<*MSNU>
handles.stat = stat;
guidata(hObject, handles);


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
    handles.isUploaded = 0;
    guidata(hObject, handles);
end

% --- Executes on button press in pbSelBMP.
function pbSelBMP_Callback(hObject, ~, handles)
% hObject    handle to pbSelBMP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[img, dir] = uigetfile('*.bmp', 'Select Image...');
imgpath = [dir filesep img];
if exist(imgpath, 'file')
    I = imread(imgpath);
    if size(I,3) > 1
        I = rgb2gray(I);
    end
    axes(handles.axImg);
    imagesc(I);
    set(gca,'XTick',[]) % Remove the ticks in the x axis
    set(gca,'YTick',[]) % Remove the ticks in the y axis
    handles.BMP = I; % make the image known to the handles struct
    handles.isUploaded = 0;
    guidata(hObject, handles); % update handles struct
end


% --- Executes on button press in tgbSync.
function tgbSync_Callback(hObject, eventdata, handles)
% hObject    handle to tgbSync (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tgbSync
if get(hObject, 'Value')
    % check, if cycle is running
    nextc = cSync(handles);
    
    % if not, show warning and set sync toggle button to off
    if nextc == -100
        warndlg('Cycle is not running. Start cycle and retry!');
        set(hObject, 'Value', 'Off')
    else
        while get(hObject, 'Value')
            % if it is running, pause the dmd
            tgbPause_Callback(hObject, eventdata, handles)
            % check the status, wait and play the
            % dmd sequence
            if ~handles.inSync
                [nextc, len] = cSync(handles);
                statusbar('Wait for cycle to end...');
                if floor(nextc) > 1
                    for i = 1:floor(nextc-1.5)
                        set(handles.stat.ProgressBar, 'Visible', true, 'Minimum',0, ...
                            'Maximum', len, 'Value', len-nextc+i);
                        pause(1);
                    end
                end
                handles.inSync = 1;
                guidata(hObject, handles); % update handles struct
            end
            [nextc, len] = cSync(handles);
            tstart = timer('StartDelay',nextc+str2double(get(handles.edDelayT, 'String')) ...
                ,'ExecutionMode', 'singleShot');
            tstart.TimerFcn = {@tgbPlay_Callback, handles};
            tstop = timer('StartDelay',nextc+str2double(get(handles.edDelayT, 'String'))+ ...
                str2double(get(handles.edOnT, 'String')), ...
                'ExecutionMode', 'singleShot');
            tstop.TimerFcn = {@tgbPause_Callback, handles};
            
            tprog = timer('StartDelay',nextc,'ExecutionMode', 'fixedRate', ...
                'TasksToExecute', floor(len-1), 'Period', 1);
            tprog.TimerFcn = {@cProgressBar_Callback, handles};
            
            start(tstart);
            start(tstop);
            start(tprog);
            wait(tstop);
        end
        wait(tprog);
        handles.inSync = 0;
        guidata(hObject, handles); % update handles struct
        set(handles.stat.ProgressBar, 'Visible', false);
    end
end


function cProgressBar_Callback(hObject, eventdata, handles)
% hObject    handle to edDelayT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% nextc      seconds until next cycle start
% len        cycle length in total in seconds

[nc, l] = cSync(handles);
set(handles.stat.ProgressBar, 'Visible', true, 'Minimum',0, ...
    'Maximum', l, 'Value', l - nc);


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
if isfield(handles, 'BMP')
    set(handles.tgbStop, 'Enable', 'on');
    set(handles.tgbPause, 'Enable', 'on');
    set(handles.tgbPlay, 'Enable', 'off');
    d = handles.d;
    stat = handles.stat;
    if d.sleeping
        d.wakeup
        set(stat.ProgressBar, 'Visible', true,  ...
            'Minimum',0, 'Maximum',100, 'Value', 20);
        statusbar('Woke up DMD...');
    end
    if handles.isUploaded
        d.patternControl(2);
    else
        statusbar('Generate BMP and upload...');
        d.display(handles.BMP);
        set(stat.ProgressBar, 'Value', 60);
        statusbar('Uploaded...');
        handles.isUploaded = 1;
        guidata(hObject, handles);
    end
    setDMDstatus(handles);
else
    warndlg('You have to specify an image first!');
end

% --- Executes on button press in tgbPause.
function tgbPause_Callback(hObject, eventdata, handles)
% hObject    handle to tgbPause (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tgbPause
set(handles.tgbStop, 'Enable', 'on');
set(handles.tgbPause, 'Enable', 'off');
set(handles.tgbPlay, 'Enable', 'on');
d = handles.d;
d.patternControl(1);
setDMDstatus(handles);


% --- Executes on button press in tgbStop.
function tgbStop_Callback(hObject, eventdata, handles)
% hObject    handle to tgbStop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tgbStop
set(handles.tgbStop, 'Enable', 'off');
set(handles.tgbPause, 'Enable', 'off');
set(handles.tgbPlay, 'Enable', 'on');
d = handles.d;
d.patternControl(0);
d.sleep;
handles.isUploaded = 0;
setDMDstatus(handles);
guidata(hObject, handles); % update handles struct


% --- Executes on button press in pbFlatF.
function pbFlatF_Callback(hObject, eventdata, handles)
% hObject    handle to pbFlatF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

