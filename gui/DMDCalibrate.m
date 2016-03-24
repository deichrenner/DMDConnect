function varargout = DMDCalibrate(varargin)
% DMDCALIBRATE MATLAB code for DMDCalibrate.fig
%      DMDCALIBRATE, by itself, creates a new DMDCALIBRATE or raises the existing
%      singleton*.
%
%      H = DMDCALIBRATE returns the handle to a new DMDCALIBRATE or the handle to
%      the existing singleton*.
%
%      DMDCALIBRATE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DMDCALIBRATE.M with the given input arguments.
%
%      DMDCALIBRATE('Property','Value',...) creates a new DMDCALIBRATE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DMDCalibrate_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DMDCalibrate_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DMDCalibrate

% Last Modified by GUIDE v2.5 09-Mar-2016 16:39:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DMDCalibrate_OpeningFcn, ...
                   'gui_OutputFcn',  @DMDCalibrate_OutputFcn, ...
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


% --- Executes just before DMDCalibrate is made visible.
function DMDCalibrate_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DMDCalibrate (see VARARGIN)

% Choose default command line output for DMDCalibrate
handles.output = hObject;

jCalCode = com.mathworks.widgets.SyntaxTextPane;
codeType = jCalCode.M_MIME_TYPE;  % ='text/m-MATLAB'
jCalCode.setContentType(codeType)
str = ['dmdsize = [1920, 1080];\n' ...
    'xx = [500 1400 500 1400];\n' ...
    'yy = [200 200 800 800];\n' ...
    'plot(xx,yy,''kx'',''MarkerSize'',10,''LineWidth'',2);\n' ...
    'xlim([1 1920]);\n' ...
    'ylim([1 1080]);\n' ...
    'set(gca,''XTick'',[]) % Remove the ticks in the x axis\n' ...
    'set(gca,''YTick'',[]) % Remove the ticks in the y axis\n' ...
    'text(960,800,''Top'',''FontSize'',16,''HorizontalAlignment'',''center'');\n' ...
    'text(960,200,''Bottom'',''FontSize'',16,''HorizontalAlignment'',''center'');'];
str = sprintf(strrep(str,'%','%%'));
jCalCode.setText(str);
jScrollPane = com.mathworks.mwswing.MJScrollPane(jCalCode);
javacomponent(jScrollPane,[310,313,480,130],gcf);
jCalCode.setCaretPosition(1);

handles.jCalCode = jCalCode;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DMDCalibrate wait for user response (see UIRESUME)
% uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = DMDCalibrate_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pbGenCalSc.
function pbGenCalSc_Callback(hObject, eventdata, handles)
% hObject    handle to pbGenCalSc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set the source image axis as the current axis
axes(handles.axSrc);
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
    % copy axis content and save with required resolution
    f1 = figure;
    set(f1, 'Visible', 'off');
    copyobj(handles.axSrc,f1);
    xlim([1 1920]);
    ylim([1 1080]);
    set(gca,'XTick',[]) % Remove the ticks in the x axis!
    set(gca,'YTick',[]) % Remove the ticks in the y axis
    set(gca,'Units','Normalized');
    set(gca,'Position',[0 0 1 1]) % Make the axes occupy the hole figure
    t = findall(gca,'type','text');
    fs = get(t, 'FontSize');
    for i = 1:size(t)
        set(t(i), 'FontSize', 1.5*fs{i});
    end
    m = findall(gca,'type','line');
    ms = get(m, 'MarkerSize');
    set(m, 'MarkerSize', 1.8*ms);
    r = 150; % pixels per inch
    set(f1, 'PaperUnits', 'inches', 'PaperPosition', [0 0 1920 1080]/r);
    print(f1,'-dbmpmono',sprintf('-r%d',r), [tempdir 'tmp.bmp']);
    close(f1);
   
    % load tmp.bmp and assign to handles.calSrc
    calSrc = imread([tempdir 'tmp.bmp']);
    delete([tempdir 'tmp.bmp']);
    handles.calSrc = calSrc;
    guidata(hObject, handles);
end

% --- Executes on button press in pbLoadCalRes.
function pbLoadCalRes_Callback(hObject, eventdata, handles)
% hObject    handle to pbLoadCalRes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[img, dir] = uigetfile('*.png', 'Select Calibration Image...');
imgpath = [dir filesep img];
if exist(imgpath, 'file')
    calRes = rgb2gray(imread(imgpath));
    axes(handles.axRes);
    if any(size(calRes) == [400 400]) 
        calRes = padarray(calRes, [56 56]);
    elseif any(size(calRes) == [200 200])
        calRes = padarray(calRes, 28);
    end
    imagesc(calRes); axis image;
    xlim([1 512]);
    ylim([1 512]);
    set(gca,'XTick',[]) % Remove the ticks in the x axis
    set(gca,'YTick',[]) % Remove the ticks in the y axis
    handles.calRes = calRes; % make the image known to the handles struct
    guidata(hObject, handles); % update handles struct
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


function edtCalCode_Callback(hObject, eventdata, handles)
% hObject    handle to edtCalCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtCalCode as text
%        str2double(get(hObject,'String')) returns contents of edtCalCode as a double


% --- Executes during object creation, after setting all properties.
function edtCalCode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtCalCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pbDispSrc.
function pbDispSrc_Callback(hObject, eventdata, handles)
% hObject    handle to pbDispSrc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
d = DMD('debug',0);
d.display(handles.calSrc);
handles.d = d;
guidata(hObject, handles); % update handles struct



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.d.delete;

% Hint: delete(hObject) closes the figure
delete(hObject);


