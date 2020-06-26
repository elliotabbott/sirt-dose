function varargout = histmap(varargin)
% HISTMAP MATLAB code for histmap.fig
%      HISTMAP, by itself, creates a new HISTMAP or raises the existing
%      singleton*.
%
%      H = HISTMAP returns the handle to a new HISTMAP or the handle to
%      the existing singleton*.
%
%      HISTMAP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HISTMAP.M with the given input arguments.
%
%      HISTMAP('Property','Value',...) creates a new HISTMAP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before histmap_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to histmap_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help histmap

% Last Modified by GUIDE v2.5 20-Jan-2017 18:34:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @histmap_OpeningFcn, ...
    'gui_OutputFcn',  @histmap_OutputFcn, ...
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


% --- Executes just before histmap is made visible.
function histmap_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to histmap (see VARARGIN)

% Choose default command line output for histmap
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes histmap wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%FIXME delete below
load_pushbutton_Callback(hObject, eventdata, handles)


% --- Outputs from this function are returned to the command line.
function varargout = histmap_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on scroll wheel click while the figure is in focus.
function figure1_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)
%TODO make scroll only if mouse current position is inside image (axes
%position)
go_to_sequential_slice(hObject, eventdata, handles, eventdata.VerticalScrollCount);

function go_to_sequential_slice(hObject, eventdata, handles, step)
num_slices = count_slices(hObject, eventdata, handles);
destination_slice = handles.slice_slider.Value - step;
if destination_slice > num_slices
    destination_slice = mod(destination_slice, num_slices);
elseif destination_slice < 1
    destination_slice = num_slices;
end
set(handles.slice_slider,'Value',destination_slice);
set(handles.slice_edit,'String',num2str(destination_slice));
update_image(hObject, eventdata, handles);

function filepath_edit_Callback(hObject, eventdata, handles)
filepath = hObject.String;
load_file(hObject, eventdata, handles, filepath);


function filepath_edit_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function load_pushbutton_Callback(hObject, eventdata, handles)
%load file
%FIXME uncomment
%TODO implement matfile() fn to Load Parts of Variables from MAT-Files for
%quicker running and/or implementing a waitbar
%[FileName,PathName] = uigetfile('*.mat','Select the MATLAB variables file');
%if PathName ~= 0
%    filepath = [PathName FileName];
parentpath = cd('..');
cd(parentpath);
filepath = [parentpath '\sample_tables.mat'];
load_file(hObject, eventdata, handles, filepath);
set(handles.filepath_edit,'String',filepath);
%end


function load_file(hObject, eventdata, handles, filepath)
set(handles.figure1, 'pointer', 'watch');
drawnow;
if exist(filepath,'file') == 2
    handles.patients = load(filepath);
    
    %adjust other uicontrols
    set(handles.patient_popupmenu,'String',fieldnames(handles.patients));
    set(handles.slice_slider,'Enable','on');
    set_colormap(hObject, eventdata, handles);
    update_controls(hObject, eventdata, handles);
    handles.histogram_data = get_histogram_data(hObject, eventdata, handles);
    update_histogram(hObject, eventdata, handles);
    handles.image_data = get_image_data(hObject, eventdata, handles);
    
    % Update handles structure
    guidata(hObject, handles);
else
    beep
    errordlg('Valid *.mat file not selected','File Not Loaded','modal');
end
set(handles.figure1, 'pointer', 'arrow');



function update_controls(hObject, eventdata, handles)
%determine and set attributes from patient table
patient_name = selected_patient_name(hObject, eventdata, handles);
attributes = handles.patients.(patient_name).Properties.VariableNames(11:end);
set(handles.attribute_popupmenu,'String',attributes);

%determine and set tissues list from patient table
base = {'Whole Liver'; 'All Tumours'; 'Normal Liver'};
%add tumour labels
num_tumours = count_tumours(hObject, eventdata, handles);
tumours = cell(num_tumours, 1);
for i = 1 : num_tumours
    tumours{i, 1} = ['Tumour ' num2str(i)];
end
set(handles.tissues_listbox,'String',[base; tumours]);

%determine and set slice controls
num_slices = count_slices(hObject, eventdata, handles);
set(handles.slice_slider,'Value',round(num_slices/2));
set(handles.slice_slider,'Max',num_slices);
set(handles.slice_slider,'SliderStep',[1/(num_slices-1), 1/(num_slices-1)]);
set(handles.slice_edit,'String',handles.slice_slider.Value);
set(handles.max_slice_text,'String',['of ' num2str(num_slices)]);

% Update handles structure
guidata(hObject, handles);


function patient_popupmenu_Callback(hObject, eventdata, handles)
update_controls(hObject, eventdata, handles);
handles.image_data = get_image_data(hObject, eventdata, handles);
update_image(hObject, eventdata, handles);
handles.histogram_data = get_histogram_data(hObject, eventdata, handles);
update_histogram(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);


function patient_popupmenu_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function slice_slider_Callback(hObject, eventdata, handles)
new_value = round(get(hObject,'Value'));
set(handles.slice_edit,'String',new_value);
update_image(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);


function slice_slider_CreateFcn(hObject, eventdata, handles)

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function slice_edit_Callback(hObject, eventdata, handles)
handles.slice_slider.Value = str2double(get(hObject,'String'));
update_image(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);


function slice_edit_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function loop_togglebutton_Callback(hObject, eventdata, handles)
while hObject.Value
    go_to_sequential_slice(hObject, eventdata, handles, -1)
end

function speed_edit_Callback(hObject, eventdata, handles)


function speed_edit_CreateFcn(hObject, eventdata, handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function attribute_popupmenu_Callback(hObject, eventdata, handles) %TODO REDO/clean up colormap code
%upon changing attribute, determine default bins (if auto is selected),
%colormap, and update figure
%bins
if handles.bins_auto_checkbox.Value
    set_bin_defaults(hObject, eventdata, handles);
end
%colormap
attribute = selected_attribute(hObject, eventdata, handles);
switch attribute
    case 'dose'
        cmap = 'jet';
    case 'ID'
        cmap = 'colours';
    case 'BED'
        cmap = 'hot';
    case 'EQD2'
        cmap = 'copper';
    case 'NTCP'
        cmap = 'red';
    case 'TCP'
        cmap = 'green';
    otherwise
        error('%s is not a valid attribute', attribute);
end
%find row in colourmap_popupmenu with value of cmap
colormap_options = get(handles.colourmap_popupmenu,'String');
selection = ind2sub(size(colormap_options),find(cellfun(@(x)strcmp(x,cmap),colormap_options))); %find index of selected colormap popup string
if ~isempty(selection)
    set(handles.colourmap_popupmenu,'Value',selection);
    set_colormap(hObject, eventdata, handles);
    handles.image_data = get_image_data(hObject, eventdata, handles);
    update_image(hObject, eventdata, handles);
    handles.histogram_data = get_histogram_data(hObject, eventdata, handles);
    update_histogram(hObject, eventdata, handles);
    
    % Update handles structure
    guidata(hObject, handles);
else
    error('%s is not a valid colourmap',cmap);
end

function cmap = get_colourmap(hObject, eventdata, handles)
colourmaps = cellstr(get(handles.colourmap_popupmenu,'String'));
cmap = colourmaps{get(handles.colourmap_popupmenu,'Value')};


function patient_name = selected_patient_name(hObject, eventdata, handles)
%determine currently selected patient name as string
patient_names_list = cellstr(get(handles.patient_popupmenu,'String'));
patient_name = patient_names_list{get(handles.patient_popupmenu,'Value')};


function attribute = selected_attribute(hObject, eventdata, handles)
%determine attribute name as string
attributes = get(handles.attribute_popupmenu,'String');
attribute_index = get(handles.attribute_popupmenu,'Value');
attribute = attributes{attribute_index};


function num_tumours = count_tumours(hObject, eventdata, handles)
patient_name = selected_patient_name(hObject, eventdata, handles);
num_tumours = max(handles.patients.(patient_name).ID);

function num_slices = count_slices(hObject, eventdata, handles)
patient_name = selected_patient_name(hObject, eventdata, handles);
num_slices = max(handles.patients.(patient_name).z);

function bin_settings(hObject, eventdata, handles, width, min, max)
%adjust bin settings
handles.bin_width_edit.String = width;
handles.bin_min_edit.String = min;
handles.bin_max_edit.String = max;

% Save the handles structure.
guidata(hObject,handles);


function attribute_popupmenu_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function colourmap_popupmenu_Callback(hObject, eventdata, handles)
set_colormap(hObject, eventdata, handles);


function colourmap_popupmenu_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function set_colormap(hObject, eventdata, handles, cmap)
if nargin == 3
    cmap = get_colourmap(hObject, eventdata, handles);
end
switch cmap
    case 'colours'
        cmap = [1,1,1;1,0,0;0,0.5,0;0,0,1;1,1,0;1,0,1;0,1,1;0,1,0];
        %FIXME bug that only allows colormap of 'colours' length
    case 'red'
        cmap = zeros(64,3);
        cmap(:,1)=(0:63)'/63;
    case 'green'
        cmap = zeros(64,3);
        cmap(:,2)=(0:63)'/63;
    case 'blue'
        cmap = zeros(64,3);
        cmap(:,3)=(0:63)'/63;
    otherwise
end
colormap(cmap);


function tissues_listbox_Callback(hObject, eventdata, handles)


function tissues_listbox_CreateFcn(hObject, eventdata, handles)

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function smooth_checkbox_Callback(hObject, eventdata, handles)


function xlim_min_edit_Callback(hObject, eventdata, handles)
handles.histogram.XLim(1) = str2double(handles.xlim_min_edit.String);
handles.image.CLim(1) = handles.histogram.XLim(1);



function xlim_min_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function xlim_max_edit_Callback(hObject, eventdata, handles)
%TODO make font and position consistent with other numbers and remove the
%underlying value (for each lim max or min edit box)
handles.histogram.XLim(2) = str2double(handles.xlim_max_edit.String);
handles.image.CLim(2) = handles.histogram.XLim(2);


function xlim_max_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ylim_min_edit_Callback(hObject, eventdata, handles)
handles.histogram.YLim(1) = str2double(handles.ylim_min_edit.String);


function ylim_min_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function ylim_max_edit_Callback(hObject, eventdata, handles)
handles.histogram.YLim(2) = str2double(handles.ylim_max_edit.String);


function ylim_max_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function bins_auto_checkbox_Callback(hObject, eventdata, handles)
if hObject.Value == 1 %checked
    set(handles.bin_width_edit,'Enable','inactive');
    set(handles.bin_min_edit,'Enable','inactive');
    set(handles.bin_max_edit,'Enable','inactive');
    set_bin_defaults(hObject, eventdata, handles);
    handles.histogram_data = get_histogram_data(hObject, eventdata, handles);
    update_histogram(hObject, eventdata, handles);
elseif hObject.Value == 0 %unchecked
    set(handles.bin_width_edit,'Enable','on');
    set(handles.bin_min_edit,'Enable','on');
    set(handles.bin_max_edit,'Enable','on');
end


function set_bin_defaults(hObject, eventdata, handles)
attribute = selected_attribute(hObject, eventdata, handles);
switch attribute
    case 'ID'
        num_tumours = count_tumours(hObject, eventdata, handles);
        bin_settings(hObject, eventdata, handles, 1, -0.5, num_tumours + 0.5 );
    case {'TCP','NTCP'}
        bin_settings(hObject, eventdata, handles, 0.01, 0, 1);
    otherwise
        bin_settings(hObject, eventdata, handles, 1, 0, 120);
end


function bin_width_edit_Callback(hObject, eventdata, handles)
handles.histogram_data = get_histogram_data(hObject, eventdata, handles);
update_histogram(hObject, eventdata, handles);

function bin_width_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function bin_min_edit_Callback(hObject, eventdata, handles)
handles.histogram_data = get_histogram_data(hObject, eventdata, handles);
update_histogram(hObject, eventdata, handles);


function bin_min_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function bin_max_edit_Callback(hObject, eventdata, handles)
handles.histogram_data = get_histogram_data(hObject, eventdata, handles);
update_histogram(hObject, eventdata, handles);


function bin_max_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function image_CreateFcn(hObject, eventdata, handles)


function histogram_data = get_histogram_data(hObject, eventdata, handles)
%create subtable to simplify data access for readability
patient_name = selected_patient_name(hObject, eventdata, handles);
data = handles.patients.(patient_name);
attribute = selected_attribute(hObject, eventdata, handles);
data = data(:,{'Liver','Tumour','ID',attribute});
%base
[histogram_data.whole_liver, histogram_data.edges] = make_histogram_counts(hObject, eventdata, handles,...
    data(data.Liver==true, attribute));
histogram_data.all_tumours = make_histogram_counts(hObject, eventdata, handles,...
    data(data.Liver==true & data.Tumour==true, attribute));
histogram_data.normal_liver = make_histogram_counts(hObject, eventdata, handles,...
    data(data.ID==0, attribute));
%individual tumours
for i = 1:max(data.ID)
    histogram_data.tumour{i} = make_histogram_counts(hObject, eventdata, handles,...
        data(data.ID==i, attribute));
end

function [histogram_counts, histogram_edges] = make_histogram_counts(hObject, eventdata, handles, table)
[histogram_counts, histogram_edges] = histcounts(table2array(table),...
    'BinWidth',str2double(handles.bin_width_edit.String),...
    'BinLimits',[str2double(handles.bin_min_edit.String),str2double(handles.bin_max_edit.String)],...
    'Normalization','pdf');
if handles.cumulative_radiobutton.Value == 1
    histogram_counts = cumsum(histogram_counts,'reverse');
end


function image_data = get_image_data(hObject, eventdata, handles)
patient_name = selected_patient_name(hObject, eventdata, handles);
attribute = selected_attribute(hObject, eventdata, handles);
image_data = table2mat(handles.patients.(patient_name),attribute);
%make image
%TODO if map radiobutton is pushed and smooth
imagesc(handles.image, image_data(:,:,handles.slice_slider.Value)');
%TODO incorporate all the following into the imagesc function
set(handles.image,'CLim',[str2double(handles.xlim_min_edit.String), str2double(handles.xlim_max_edit.String)]);
set(handles.image,'DataAspectRatio',[1 1 1]);
set(handles.image,'YTick',[]);
set(handles.image,'XTick',[]);
%make colorbar
%TODO incorporate all the following into the colorbar function
handles.colorbar = colorbar(handles.image,'north');
%TODO make ticks go all the way through the colorbar and make the tick
%values and label appear below the colorbar...possibly put the
%popupmenu below?
handles.colorbar.TickLength = handles.colorbar.Position(4);
handles.colorbar.Position(1:3) = handles.histogram.Position(1:3);
handles.colorbar.Position(2) = handles.histogram.Position(2)-handles.colorbar.Position(4);
switch attribute
    case 'dose'
        handles.colorbar.Label.String = 'Dose (Gy)';
    case 'ID'
        handles.colorbar.Label.String = 'ID';
    case 'BED'        
        handles.colorbar.Label.String = 'BED (Gy)';
    case 'EQD2'        
        handles.colorbar.Label.String = 'EQD_2 (Gy)';
    case 'NTCP'
        handles.colorbar.Label.String = 'NTCP';
    case 'TCP'
        handles.colorbar.Label.String = 'TCP';
    otherwise
        handles.colorbar.Label.String = attribute;
end

% Update handles structure
guidata(hObject, handles);

function update_image(hObject, eventdata, handles)
current_slice = str2double(handles.slice_edit.String);
handles.image.Children.CData = handles.image_data(:,:,current_slice)';
pause(0.1/str2double(handles.speed_edit.String));
drawnow;


function update_histogram(hObject, eventdata, handles)
cla(handles.histogram);
hold(handles.histogram,'on');
stairs(handles.histogram,handles.histogram_data.edges(1:end-1),handles.histogram_data.whole_liver);
stairs(handles.histogram,handles.histogram_data.edges(1:end-1),handles.histogram_data.all_tumours);
stairs(handles.histogram,handles.histogram_data.edges(1:end-1),handles.histogram_data.normal_liver);
hold(handles.histogram,'off');
update_limits(hObject, eventdata, handles);

drawnow;


function update_limits(hObject, eventdata, handles)
%set edit boxes to histogram limits
handles.xlim_min_edit.String = handles.histogram.XLim(1);
handles.xlim_max_edit.String = handles.histogram.XLim(2);
handles.ylim_min_edit.String = handles.histogram.YLim(1);
handles.ylim_max_edit.String = handles.histogram.YLim(2);
%set image limits to histogram limits
handles.image.CLim = handles.histogram.XLim;


function y_axis_popupmenu_Callback(hObject, eventdata, handles)


function maximum = get_max(hObject, eventdata, handles)
%determines the patient's maximum attribute current value
patient_name = selected_patient_name(hObject, eventdata, handles);
attribute = selected_attribute(hObject, eventdata, handles);
maximum = max(handles.patients.(patient_name).(attribute));


% --- Executes on button press in cumulative_radiobutton.
function cumulative_radiobutton_Callback(hObject, eventdata, handles)
handles.histogram_data = get_histogram_data(hObject, eventdata, handles);
update_histogram(hObject, eventdata, handles);


% --- Executes on button press in differential_radiobutton.
function differential_radiobutton_Callback(hObject, eventdata, handles)
handles.histogram_data = get_histogram_data(hObject, eventdata, handles);
update_histogram(hObject, eventdata, handles);
