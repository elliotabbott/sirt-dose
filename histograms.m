function varargout = histograms(varargin)
% HISTOGRAMS MATLAB code for histograms.fig
%      HISTOGRAMS, by itself, creates a new HISTOGRAMS or raises the existing
%      singleton*.
%
%      H = HISTOGRAMS returns the handle to a new HISTOGRAMS or the handle to
%      the existing singleton*.
%
%      HISTOGRAMS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HISTOGRAMS.M with the given input arguments.
%
%      HISTOGRAMS('Property','Value',...) creates a new HISTOGRAMS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before histograms_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to histograms_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help histograms

% Last Modified by GUIDE v2.5 11-Jan-2017 17:53:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @histograms_OpeningFcn, ...
    'gui_OutputFcn',  @histograms_OutputFcn, ...
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


% --- Executes just before histograms is made visible.
function histograms_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to histograms (see VARARGIN)

%TODO create a row of histograms, create a waterfall plot of histograms,
%incorporate histograms into a single figure with the maps

handles.patient = varargin{1};

%update axes
update_axes(hObject, eventdata, handles);

% Choose default command line output for histograms
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes histograms wait for user response (see UIRESUME)
% uiwait(handles.histograms);


% --- Outputs from this function are returned to the command line.
function varargout = histograms_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Updates axes.
function update_axes(hObject, eventdata, handles)
%determine axes attribute setting
attribute_list = cellstr(get(handles.attribute_popupmenu,'String'));
handles.attribute = attribute_list{get(handles.attribute_popupmenu,'Value')};
switch handles.attribute
    case 'dose'
        handles.xlabel_text = 'Dose (Gy)';
%         bin_settings(hObject, eventdata, handles, 1, 0, 120);
    case 'ID'
        handles.xlabel_text = 'ID';
%         bin_settings(hObject, eventdata, handles, 1, -0.5, max(handles.patient.ID)+0.5);
    case 'BED'
        handles.xlabel_text = 'BED (Gy)';
%         bin_settings(hObject, eventdata, handles, 1, 0, 120);
    case 'EQD2'
        handles.xlabel_text = 'EQD2 (Gy)';
%         bin_settings(hObject, eventdata, handles, 1, 0, 120);
    case 'NTCP'
        handles.xlabel_text = 'NTCP';
%         bin_settings(hObject, eventdata, handles, 0.01, 0, 1);
    case 'TCP'
        handles.xlabel_text = 'TCP';
%         bin_settings(hObject, eventdata, handles, 0.01, 0, 1);
    otherwise
        error('"%s" is not a valid attribute', handles.attribute);
end

% %determine axes bin settings
% if get(handles.bins_auto_checkbox,'Value') == 1
%     default_pushbutton_Callback(hObject, eventdata, handles);
% end
handles.width = str2double(get(handles.bin_width_edit,'String'));
handles.bin_min = str2double(get(handles.bin_min_lim_edit,'String'));
handles.bin_max = str2double(get(handles.bin_max_lim_edit,'String'));

%determine axes display style
if get(handles.outline_checkbox,'Value')
    handles.disp_style = 'stairs';
else
    handles.disp_style = 'bar';
end

%determine axes normalisation settings
if get(handles.normalised_checkbox,'Value')
    handles.ylabel_text = 'Volume Fraction';
    if get(handles.cumulative_checkbox,'Value')
        normalisation = 'cdf';
    else
        normalisation = 'pdf';
    end
else
    handles.ylabel_text = 'Number of Voxels';
    if get(handles.cumulative_checkbox,'Value')
        normalisation = 'cumcount';
    else
        normalisation = 'count';
    end
end

%display axes based on histogram groupings
if get(handles.whole_liver_checkbox,'Value')
    %just whole liver
    histogram(table2array(handles.patient(handles.patient.Liver==true,handles.attribute)),...
        'BinWidth',handles.width,...
        'BinLimits',[handles.bin_min,handles.bin_max],...
        'DisplayStyle',handles.disp_style,...
        'Normalization',normalisation);
    lgnd = {'Whole Liver'};
else
    %normal liver and...
    histogram(table2array(handles.patient(handles.patient.ID==0,handles.attribute)),...
        'BinWidth',handles.width,...
        'BinLimits',[handles.bin_min,handles.bin_max],...
        'DisplayStyle',handles.disp_style,...
        'Normalization',normalisation);
    lgnd = {'Normal Liver'};
    hold on
    %tumour
    if get(handles.tumours_checkbox,'Value')
        %collective tumours
        histogram(table2array(handles.patient(handles.patient.Liver==true & handles.patient.Tumour==true,handles.attribute)),...
            'BinWidth',handles.width,...
            'BinLimits',[handles.bin_min,handles.bin_max],...
            'DisplayStyle',handles.disp_style,...
            'Normalization',normalisation);
        lgnd = [lgnd 'Tumour'];
    else
        %individual tumours
        for i = 1:max(handles.patient.ID)
            histogram(table2array(handles.patient(handles.patient.ID==i,handles.attribute)),...
                'BinWidth',handles.width,...
                'BinLimits',[handles.bin_min,handles.bin_max],...
                'DisplayStyle',handles.disp_style,...
                'Normalization',normalisation);
            lgnd = [lgnd ['Tumour ' num2str(i)]]; %#ok<AGROW>
        end
    end
end
legend(lgnd);
xlabel(handles.xlabel_text);
ylabel(handles.ylabel_text);
hold off

% --- Executes on selection change in patient_popupmenu.
function patient_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to patient_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns patient_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from patient_popupmenu


% --- Executes during object creation, after setting all properties.
function patient_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to patient_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function bin_width_edit_Callback(hObject, eventdata, handles)
% hObject    handle to bin_width_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.width = str2double(get(hObject,'String'));

update_axes(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);

% Hints: get(hObject,'String') returns contents of bin_width_edit as text
%        str2double(get(hObject,'String')) returns contents of bin_width_edit as a double


% --- Executes during object creation, after setting all properties.
function bin_width_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bin_width_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function bin_min_lim_edit_Callback(hObject, eventdata, handles)
% hObject    handle to bin_min_lim_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.bin_min = str2double(get(hObject,'String'));

update_axes(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);

% Hints: get(hObject,'String') returns contents of bin_min_lim_edit as text
%        str2double(get(hObject,'String')) returns contents of bin_min_lim_edit as a double


% --- Executes during object creation, after setting all properties.
function bin_min_lim_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bin_min_lim_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function bin_max_lim_edit_Callback(hObject, eventdata, handles)
% hObject    handle to bin_max_lim_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.bin_max = str2double(get(hObject,'String'));

update_axes(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);

% Hints: get(hObject,'String') returns contents of bin_max_lim_edit as text
%        str2double(get(hObject,'String')) returns contents of bin_max_lim_edit as a double


% --- Executes during object creation, after setting all properties.
function bin_max_lim_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bin_max_lim_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in whole_liver_checkbox.
function whole_liver_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to whole_liver_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if get(hObject,'Value')
    handles.tumours_checkbox.Enable = 'off';
else
    handles.tumours_checkbox.Enable = 'on';
end

% Update handles structure
guidata(hObject, handles);

%update axes
update_axes(hObject, eventdata, handles);

% Hint: get(hObject,'Value') returns toggle state of whole_liver_checkbox


% --- Executes on button press in tumours_checkbox.
function tumours_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to tumours_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update handles structure
guidata(hObject, handles);

%update axes
update_axes(hObject, eventdata, handles);

% Hint: get(hObject,'Value') returns toggle state of tumours_checkbox


% --- Executes on button press in cumulative_checkbox.
function cumulative_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to cumulative_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update handles structure
guidata(hObject, handles);

%update axes
update_axes(hObject, eventdata, handles);

% Hint: get(hObject,'Value') returns toggle state of cumulative_checkbox


% --- Executes on button press in normalised_checkbox.
function normalised_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to normalised_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update handles structure
guidata(hObject, handles);

%update axes
update_axes(hObject, eventdata, handles);

% Hint: get(hObject,'Value') returns toggle state of normalised_checkbox


% --- Executes during object creation, after setting all properties.
function histogram_axes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to histogram_axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate histogram_axes


% --- Executes on selection change in attribute_popupmenu.
function attribute_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to attribute_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Save the handles structure.
guidata(hObject,handles);

%update axes
update_axes(hObject, eventdata, handles);

% Hints: contents = cellstr(get(hObject,'String')) returns attribute_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from attribute_popupmenu


% --- Executes during object creation, after setting all properties.
function attribute_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to attribute_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in default_pushbutton.
function default_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to default_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = cellstr(get(handles.attribute_popupmenu,'String'));
switch contents{get(handles.attribute_popupmenu,'Value')}
    case {'NTCP','TCP'}
        bin_settings(hObject, eventdata, handles, .01, 0, 1);
    case 'ID'
        bin_settings(hObject, eventdata, handles, 1, 0, max(handles.patient.ID));
    otherwise
        bin_settings(hObject, eventdata, handles, 1, 0, 120);
end

% Save the handles structure.
guidata(hObject,handles);

%update axes
update_axes(hObject, eventdata, handles);

function bin_settings(hObject, eventdata, handles, width, min, max)
%adjust bin settings
handles.bin_width_edit.String = width;
handles.bin_min_lim_edit.String = min;
handles.bin_max_lim_edit.String = max;

% Save the handles structure.
guidata(hObject,handles);


% --- Executes on button press in outline_checkbox.
function outline_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to outline_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Save the handles structure.
guidata(hObject,handles);


% Hint: get(hObject,'Value') returns toggle state of outline_checkbox


function bins_auto_checkbox_Callback(hObject, eventdata, handles)

%update axes
update_axes(hObject, eventdata, handles);
