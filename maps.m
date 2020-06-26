function varargout = maps(varargin)
% MAPS MATLAB code for maps.fig
%      MAPS, by itself, creates a new MAPS or raises the existing
%      singleton*.
%
%      H = MAPS returns the handle to a new MAPS or the handle to
%      the existing singleton*.
%
%      MAPS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAPS.M with the given input arguments.
%
%      MAPS('Property','Value',...) creates a new MAPS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before maps_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to maps_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help maps

% Last Modified by GUIDE v2.5 04-Jan-2017 11:26:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @maps_OpeningFcn, ...
                   'gui_OutputFcn',  @maps_OutputFcn, ...
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


% --- Executes just before maps is made visible.
function maps_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to maps (see VARARGIN)

handles.attribute = cellstr(get(handles.attribute_popupmenu,'String'));

%convert table to image matrix
map = table2mat(varargin{1},handles.attribute{get(handles.attribute_popupmenu,'Value')});

handles.slice_slider.Min = 1;
handles.slice_slider.Max = size(map,3);
handles.slice_slider.SliderStep = [1/(handles.slice_slider.Max-1), 1/(handles.slice_slider.Max-1)];
handles.total_slices_text.String = ['of ' num2str(handles.slice_slider.Max)];
handles.slice_slider.Value = round(size(map,3)/2);
handles.slice_edit.String = handles.slice_slider.Value;
imagesc(map(:,:,str2double(get(handles.slice_edit,'String'))),[0 max(map(:))]);

% Choose default command line output for maps
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes maps wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = maps_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Loop through and display slices
function loop_slices(hObject, eventdata, handles)
%loop through slices
    while isequal(handles.play_pause_uitoggletool.State,'on')
        for i = 1 : handles.slice_slider.Max
            %check that figure is open before executing iteration
            if isequal(handles.play_pause_uitoggletool.State,'off')
                break
            end
            
            %display data
            imagesc(x(:,:,i)',[0 max(x(:))]);
            axis off
          
            %create colormap
            colormap(cmap)
            c = colorbar;
            
            %create ylabel
            ylabel(c,ylabel_text);
            
            pause(0.05);
        end
    end


function slice_edit_Callback(hObject, eventdata, handles)
% hObject    handle to slice_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.slice_slider.Value = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% Hints: get(hObject,'String') returns contents of slice_edit as text
%        str2double(get(hObject,'String')) returns contents of slice_edit as a double


% --- Executes during object creation, after setting all properties.
function slice_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slice_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in attribute_popupmenu.
function attribute_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to attribute_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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


% --- Executes on slider movement.
function slice_slider_Callback(hObject, eventdata, handles)
% hObject    handle to slice_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.slice_edit.String = round(get(hObject,'Value'));

% Update handles structure
guidata(hObject, handles);



% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slice_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slice_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in histogram_checkbox.
function histogram_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to histogram_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of histogram_checkbox


% --- Executes on selection change in colormap_popupmenu.
function colormap_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to colormap_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns colormap_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from colormap_popupmenu


% --- Executes during object creation, after setting all properties.
function colormap_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to colormap_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function axes1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes1


% --- Executes during object creation, after setting all properties.
function total_slices_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to total_slices_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function play_pause_uitoggletool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to play_pause_uitoggletool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function pause_uitoggletool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to pause_uitoggletool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function play_pause_uitoggletool_OffCallback(hObject, eventdata, handles)
% hObject    handle to play_pause_uitoggletool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%change CData to pause button


% --------------------------------------------------------------------
function play_pause_uitoggletool_OnCallback(hObject, eventdata, handles)
% hObject    handle to play_pause_uitoggletool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%change CData to play button
