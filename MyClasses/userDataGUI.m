function varargout = userDataGUI(varargin)
% USERDATAGUI MATLAB code for userDataGUI.fig
%      USERDATAGUI, by itself, creates a new USERDATAGUI or raises the existing
%      singleton*.
%
%      H = USERDATAGUI returns the handle to a new USERDATAGUI or the handle to
%      the existing singleton*.
%
%      USERDATAGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in USERDATAGUI.M with the given input arguments.
%
%      USERDATAGUI('Property','Value',...) creates a new USERDATAGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before userDataGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to userDataGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help userDataGUI

% Last Modified by GUIDE v2.5 27-Aug-2024 18:09:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @userDataGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @userDataGUI_OutputFcn, ...
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


% --- Executes just before userDataGUI is made visible.
function userDataGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to userDataGUI (see VARARGIN)

% Choose default command line output for userDataGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes userDataGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = userDataGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.fileName;

% Close the GUI
delete(hObject);



function fileNameedt_Callback(hObject, eventdata, handles)
% hObject    handle to fileNameedt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fileNameedt as text
%        str2double(get(hObject,'String')) returns contents of fileNameedt as a double


% --- Executes during object creation, after setting all properties.
function fileNameedt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileNameedt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in savebtn.
function savebtn_Callback(hObject, eventdata, handles)
% hObject    handle to savebtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.fileName = get(handles.fileNameedt, 'String');

% Update handles structure
guidata(hObject, handles);

uiresume(handles.figure1);
